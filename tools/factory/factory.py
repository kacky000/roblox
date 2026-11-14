"""
日次ファクトリー：毎日1本以上作る → 公開する → 数字を取る → 機械的に判定する → 伸びているものを更新する

  python tools/factory/factory.py status            台帳の一覧
  python tools/factory/factory.py next              今日作るネタ（backlog の先頭）を表示
  python tools/factory/factory.py add <slug>        作ったゲームを台帳に登録（tools/check.sh が通ってから）
  python tools/factory/factory.py publish <slug>    rojo build → Open Cloud で公開（空きスロットを割り当てる）
  python tools/factory/factory.py smoke <slug>      Roblox のサーバー上で起動テスト（Luau Execution）
  python tools/factory/factory.py metrics           公開中の全ゲームの数字を Analytics API から取得
  python tools/factory/factory.py decide            ルール（factory/rules.json）で判定し、今日の作業リストを出す
  python tools/factory/factory.py report            factory/reports/<日付>.md を書く
  python tools/factory/factory.py selftest          判定ロジックの自己テスト（API 不要）

API キーは環境変数 ROBLOX_API_KEY か、リポジトリ直下の .env（git 管理外）から読む。キーは表示しない。
必要な権限：universe-places:write（公開）、universe-analytics の universe.analytics:read（数字）。
手順の全体は factory/README.md。標準ライブラリだけで動く。
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FACTORY = os.path.join(ROOT, "factory")
API = "https://apis.roblox.com"

# 取得する指標（docs/roblox-creator-docs/cloud/guides/analytics/metrics.md の名前）。値は「期間内の最新値」と「合計」を持つ
METRICS = [
    "UniqueUsersWithPlaySessions",  # 遊んだ人数（判定の母数）
    "DailyActiveUsers",
    "AverageSessionLengthMinutes",
    "ForwardD1Retention",
    "ForwardD7Retention",
    "RFYPlayThroughRate",  # おすすめ表示から遊ばれた率
    "RFYDuration0To60",  # 初回プレイが60秒以内に終わった率（低いほど良い）
    "PayingUsersCVR",
    "DailyRevenue",
]


# ---------------------------------------------------------------- files
def load(name: str, default):
    path = os.path.join(FACTORY, name)
    if not os.path.exists(path):
        return default
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def save(name: str, data) -> None:
    os.makedirs(FACTORY, exist_ok=True)
    with open(os.path.join(FACTORY, name), "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def today() -> str:
    return dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d")


def api_key() -> str:
    key = os.environ.get("ROBLOX_API_KEY", "")
    env = os.path.join(ROOT, ".env")
    if not key and os.path.exists(env):
        with open(env, encoding="utf-8") as f:
            for line in f:
                if line.strip().startswith("ROBLOX_API_KEY="):
                    key = line.split("=", 1)[1].strip().strip('"').strip("'")
    if not key:
        sys.exit("ROBLOX_API_KEY がありません。Creator Dashboard で発行し、.env に ROBLOX_API_KEY=... と書いてください（factory/README.md）")
    return key


def find(portfolio: list, slug: str) -> dict:
    for g in portfolio:
        if g["slug"] == slug:
            return g
    sys.exit(f"台帳に {slug} がありません（先に add する）")


# ---------------------------------------------------------------- decide（純粋関数。selftest で検証する）
def summarize(game: dict) -> dict:
    """snapshots から判定用の数字を作る。率は 0〜1 にそろえる。"""
    snaps = game.get("snapshots", [])
    plays = sum(s.get("plays", 0) or 0 for s in snaps)

    def latest(key):
        for s in reversed(snaps):
            v = s.get(key)
            if v is not None:
                return v / 100 if key in ("d1", "d7", "bounce60", "ptr", "payRate") and v > 1 else v
        return None

    live = game.get("publicDate")
    days = (dt.date.fromisoformat(today()) - dt.date.fromisoformat(live)).days if live else 0
    return {"plays": plays, "daysLive": days, "d1": latest("d1"), "d7": latest("d7"), "session": latest("session"),
            "bounce60": latest("bounce60"), "ptr": latest("ptr"), "payRate": latest("payRate"),
            "revenue": sum(s.get("revenue", 0) or 0 for s in snaps)}


def decide_one(game: dict, rules: dict) -> tuple[str, str]:
    """戻り値：(判定, 理由)。判定は BUILD_ONLY / WAIT / NO_TRAFFIC / ARCHIVE / KILL / ITERATE / SCALE。"""
    if game.get("stage") in ("killed", "archived"):
        return game["stage"].upper(), "終了済み"
    if not game.get("publicDate"):
        return "BUILD_ONLY", "まだ公開していない（スロットの割り当てと公開が必要）"
    s = summarize(game)
    r = rules
    if s["plays"] < r["minPlays"]:
        if s["daysLive"] >= r["noTrafficDays"]:
            if game.get("trafficRetries", 0) >= r["maxTrafficRetries"]:
                return "ARCHIVE", f"公開{s['daysLive']}日で {s['plays']}人。入口（サムネ・題名）を変えても人が来ない"
            return "NO_TRAFFIC", f"公開{s['daysLive']}日で {s['plays']}人。サムネと題名を作り直す（少額広告も検討）"
        return "WAIT", f"{s['plays']}/{r['minPlays']}人。判定には人数が足りない"
    d1, d7, ses, bounce = s["d1"], s["d7"], s["session"], s["bounce60"]
    good = []
    if d1 is not None and d1 >= r["scale"]["d1"]:
        good.append(f"D1 {d1:.0%}")
    if d7 is not None and d7 >= r["scale"]["d7"]:
        good.append(f"D7 {d7:.0%}")
    if ses is not None and ses >= r["scale"]["session"]:
        good.append(f"セッション {ses:.1f}分")
    if len(good) >= r["scale"]["need"]:
        return "SCALE", "、".join(good)
    bad = []
    if d1 is not None and d1 < r["kill"]["d1"]:
        bad.append(f"D1 {d1:.0%}")
    if ses is not None and ses < r["kill"]["session"]:
        bad.append(f"セッション {ses:.1f}分")
    if bounce is not None and bounce > r["kill"]["bounce60"]:
        bad.append(f"60秒以内の離脱 {bounce:.0%}")
    if len(bad) >= r["kill"]["need"] or game.get("iterations", 0) >= r["maxIterations"]:
        why = "、".join(bad) or f"{r['maxIterations']}回改善しても基準に届かない"
        return "KILL", why
    if d1 is None and ses is None:
        return "WAIT", "人数は足りたが、リテンションの数字がまだ出ていない"
    return "ITERATE", f"D1 {d1 if d1 is None else format(d1, '.0%')}、セッション {ses}分。最初の5分を直す（{game.get('iterations', 0) + 1}回目）"


def score(game: dict) -> float:
    s = summarize(game)
    return (s["d1"] or 0) * 100 + (s["d7"] or 0) * 200 + (s["session"] or 0) + (s["payRate"] or 0) * 100


def decide_all(portfolio: list, rules: dict) -> list[dict]:
    out = [{"slug": g["slug"], "decision": d, "reason": why, "score": round(score(g), 1)}
           for g in portfolio for d, why in [decide_one(g, rules)]]
    # 伸ばす対象は上位 maxScale 本まで。それ以外の SCALE は維持（HOLD）にして、手を広げすぎない
    scale = sorted([o for o in out if o["decision"] == "SCALE"], key=lambda o: -o["score"])
    for o in scale[rules["maxScale"]:]:
        o["decision"], o["reason"] = "HOLD", o["reason"] + f"（伸ばす枠は上位{rules['maxScale']}本まで）"
    return out


def worklist(decisions: list[dict], backlog: list, rules: dict) -> list[str]:
    todo = []
    for o in sorted(decisions, key=lambda o: -o["score"]):
        if o["decision"] == "SCALE":
            todo.append(f"【更新】{o['slug']}：新要素を1つ足して公開する（{o['reason']}）")
    for o in decisions:
        if o["decision"] == "ITERATE":
            todo.append(f"【改善】{o['slug']}：{o['reason']}")
        elif o["decision"] == "NO_TRAFFIC":
            todo.append(f"【入口】{o['slug']}：{o['reason']}")
        elif o["decision"] in ("KILL", "ARCHIVE"):
            todo.append(f"【終了】{o['slug']}：非公開にしてスロットを空ける（{o['reason']}）")
        elif o["decision"] == "BUILD_ONLY":
            todo.append(f"【公開待ち】{o['slug']}：{o['reason']}")
    nxt = [b for b in backlog if b.get("status") == "todo"][: rules["newGamesPerDay"]]
    for b in nxt:
        todo.append(f"【新作】{b['slug']}：{b['pitch']}")
    if not nxt:
        todo.append("【ネタ切れ】backlog.json に新しいネタを10個足す（research/04 の伸びている型から）")
    return todo


# ---------------------------------------------------------------- Open Cloud
def http(method: str, url: str, key: str, body: bytes | None = None, ctype: str = "application/json"):
    req = urllib.request.Request(url, data=body, method=method, headers={"x-api-key": key, "Content-Type": ctype})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        return e.code, {"error": e.read().decode("utf-8", "replace")[:500]}


def query_metric(universe: str, metric: str, start: str, end: str, key: str):
    url = f"{API}/analytics-query-api/v1/universes/{universe}/metrics"
    body = json.dumps({"metric": metric, "granularity": "OneDay", "startTime": start, "endTime": end}).encode()
    status, res = http("POST", url, key, body)
    for _ in range(20):
        if status not in (200, 202) or res.get("done", True):
            break
        time.sleep(3)
        status, res = http("GET", f"{API}/analytics-query-api/{res['path']}", key)
    if status != 200 or "response" not in res:
        return None, None
    pts = [p.get("value") for v in res["response"].get("values", []) for p in v.get("dataPoints", [])]
    pts = [p for p in pts if p is not None]
    return (pts[-1] if pts else None), (sum(pts) if pts else None)


# ---------------------------------------------------------------- commands
def cmd_status(_):
    portfolio, rules = load("portfolio.json", []), load("rules.json", {})
    if not portfolio:
        print("台帳は空です。next → 作る → add の順に進めます")
    for o, g in zip(decide_all(portfolio, rules), portfolio):
        s = summarize(g)
        print(f"{g['slug']:<24} {g.get('stage', '?'):<9} 作成 {g['created']}  公開 {g.get('publicDate') or '-':<10} "
              f"{s['plays']:>6}人  → {o['decision']:<10} {o['reason']}")
    slots = load("slots.json", [])
    free = [s for s in slots if not s.get("slug")]
    print(f"\nスロット：空き {len(free)} / 全 {len(slots)}。backlog の残り：{sum(b.get('status') == 'todo' for b in load('backlog.json', []))} 本")


def cmd_next(_):
    todo = [b for b in load("backlog.json", []) if b.get("status") == "todo"]
    if not todo:
        sys.exit("backlog が空です。ネタを足してください")
    print(json.dumps(todo[0], ensure_ascii=False, indent=2))


def cmd_add(a):
    portfolio, backlog = load("portfolio.json", []), load("backlog.json", [])
    if not os.path.isdir(os.path.join(ROOT, "games", a.slug)):
        sys.exit(f"games/{a.slug} がありません")
    if any(g["slug"] == a.slug for g in portfolio):
        sys.exit("登録済みです")
    idea = next((b for b in backlog if b["slug"] == a.slug), {})
    portfolio.append({"slug": a.slug, "title": idea.get("title", a.slug), "pitch": idea.get("pitch", ""), "created": today(),
                      "stage": "built", "universeId": None, "placeId": None, "publicDate": None,
                      "iterations": 0, "trafficRetries": 0, "snapshots": [], "log": [f"{today()} 作成"]})
    if idea:
        idea["status"] = "built"
        save("backlog.json", backlog)
    save("portfolio.json", portfolio)
    print(f"登録しました：{a.slug}")


def cmd_publish(a):
    portfolio, slots = load("portfolio.json", []), load("slots.json", [])
    g = find(portfolio, a.slug)
    if not g.get("universeId"):
        free = next((s for s in slots if not s.get("slug")), None)
        if not free:
            sys.exit("空きスロットがありません。Creator Hub で空の体験を作り、factory/slots.json に universeId と placeId を足してください")
        free["slug"] = a.slug
        g["universeId"], g["placeId"] = str(free["universeId"]), str(free["placeId"])
    out = os.path.join(ROOT, "games", a.slug, "build", "game.rbxl")
    subprocess.run(["bash", os.path.join(ROOT, "tools", "check.sh"), f"games/{a.slug}"], check=True, cwd=ROOT)
    url = f"{API}/universes/v1/{g['universeId']}/places/{g['placeId']}/versions?versionType=Published"
    if a.dry_run:
        print(f"[dry-run] POST {url}  ({os.path.getsize(out):,} bytes)")
        return
    with open(out, "rb") as f:
        status, res = http("POST", url, api_key(), f.read(), "application/octet-stream")
    if status != 200:
        sys.exit(f"公開に失敗：HTTP {status} {res}")
    g["stage"] = "published"
    g["log"].append(f"{today()} 公開 v{res.get('versionNumber')}")
    if a.public:
        g["publicDate"] = g.get("publicDate") or today()
    save("portfolio.json", portfolio)
    save("slots.json", slots)
    print(f"公開しました：{a.slug} v{res.get('versionNumber')}（体験を「公開」に切り替えるのは Creator Hub で。切り替えたら --public を付けて記録する）")


def cmd_smoke(a):
    """Roblox のサーバー上で place を起動し、サービスの start でエラーが出ないか・歩ける世界があるかを確かめる。"""
    g = find(load("portfolio.json", []), a.slug)
    if not g.get("universeId"):
        sys.exit("まだスロットに公開していません（先に publish）")
    key = api_key()
    with open(os.path.join(ROOT, "tools", "factory", "smoke.luau"), encoding="utf-8") as f:
        script = f.read()
    base = f"{API}/cloud/v2/universes/{g['universeId']}/places/{g['placeId']}/luau-execution-session-tasks"
    status, res = http("POST", base, key, json.dumps({"script": script}).encode())
    if status != 200:
        sys.exit(f"テストを開始できません：HTTP {status} {res}")
    path = res["path"]
    for _ in range(60):
        if res.get("state") in ("COMPLETE", "FAILED", "CANCELLED"):
            break
        time.sleep(3)
        status, res = http("GET", f"{API}/cloud/v2/{path}", key)
    _, logs = http("GET", f"{API}/cloud/v2/{path}/logs", key)
    lines = [m for entry in logs.get("luauExecutionSessionTaskLogs", []) for m in entry.get("messages", [])]
    out = (res.get("output") or {}).get("results") or [{}]
    result = out[0] if out else {}
    passed = res.get("state") == "COMPLETE" and bool(result.get("ok"))
    print(json.dumps({"state": res.get("state"), "result": result, "error": res.get("error")}, ensure_ascii=False, indent=1))
    for line in lines[-30:]:
        print("  log>", line)
    print("smoke:", "通過" if passed else "失敗")
    sys.exit(0 if passed else 1)


def cmd_metrics(_):
    portfolio, key = load("portfolio.json", []), api_key()
    end = dt.datetime.now(dt.timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)
    start = end - dt.timedelta(days=1)
    names = {"UniqueUsersWithPlaySessions": "plays", "DailyActiveUsers": "dau", "AverageSessionLengthMinutes": "session",
             "ForwardD1Retention": "d1", "ForwardD7Retention": "d7", "RFYPlayThroughRate": "ptr",
             "RFYDuration0To60": "bounce60", "PayingUsersCVR": "payRate", "DailyRevenue": "revenue"}
    for g in portfolio:
        if not g.get("universeId") or not g.get("publicDate") or g.get("stage") in ("killed", "archived"):
            continue
        day = start.strftime("%Y-%m-%d")
        if any(s["date"] == day for s in g["snapshots"]):
            continue
        snap = {"date": day}
        for m in METRICS:
            last, _total = query_metric(g["universeId"], m, start.strftime("%Y-%m-%dT00:00:00Z"), end.strftime("%Y-%m-%dT00:00:00Z"), key)
            snap[names[m]] = last
        g["snapshots"].append(snap)
        print(f"{g['slug']}: {snap}")
    save("portfolio.json", portfolio)


def cmd_decide(a):
    portfolio, rules, backlog = load("portfolio.json", []), load("rules.json", {}), load("backlog.json", [])
    decisions = decide_all(portfolio, rules)
    stage = {"SCALE": "scaling", "HOLD": "scaling", "ITERATE": "testing", "WAIT": "testing", "NO_TRAFFIC": "testing"}
    for g, o in zip(portfolio, decisions):
        if o["decision"] in stage and g.get("publicDate"):
            g["stage"] = stage[o["decision"]]
        if g.get("lastDecision") != o["decision"]:
            g["log"].append(f"{today()} 判定 {o['decision']}：{o['reason']}")
            g["lastDecision"] = o["decision"]
    if not a.no_save:
        save("portfolio.json", portfolio)
    for line in worklist(decisions, backlog, rules):
        print(line)
    return decisions


def cmd_report(a):
    portfolio, rules, backlog = load("portfolio.json", []), load("rules.json", {}), load("backlog.json", [])
    decisions = decide_all(portfolio, rules)
    lines = [f"# 日次レポート {today()}", "", "| ゲーム | 段階 | 遊んだ人 | D1 | D7 | セッション | 判定 | 理由 |", "|---|---|---|---|---|---|---|---|"]
    for g, o in zip(portfolio, decisions):
        s = summarize(g)
        pct = lambda v: "-" if v is None else f"{v:.0%}"  # noqa: E731
        lines.append(f"| {g['slug']} | {g.get('stage')} | {s['plays']} | {pct(s['d1'])} | {pct(s['d7'])} | "
                     f"{'-' if s['session'] is None else round(s['session'], 1)} | {o['decision']} | {o['reason']} |")
    lines += ["", "## 今日の作業リスト", ""] + [f"- {t}" for t in worklist(decisions, backlog, rules)]
    os.makedirs(os.path.join(FACTORY, "reports"), exist_ok=True)
    path = os.path.join(FACTORY, "reports", f"{today()}.md")
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print(f"書きました：factory/reports/{today()}.md")


def cmd_selftest(_):
    rules = load("rules.json", {})
    d = lambda n: (dt.date.fromisoformat(today()) - dt.timedelta(days=n)).isoformat()  # noqa: E731

    def game(slug, days, snaps, **kw):
        return {"slug": slug, "stage": "testing", "created": d(days), "publicDate": d(days), "snapshots": snaps, **kw}

    cases = [
        (game("not-public", 0, [], publicDate=None), "BUILD_ONLY"),
        (game("too-few", 2, [{"plays": 30}]), "WAIT"),
        (game("no-traffic", 8, [{"plays": 12}]), "NO_TRAFFIC"),
        (game("no-traffic-twice", 20, [{"plays": 40}], trafficRetries=1), "ARCHIVE"),
        (game("winner", 9, [{"plays": 400, "d1": 0.24, "d7": 0.08, "session": 14}]), "SCALE"),
        (game("winner-percent", 3, [{"plays": 300, "d1": 23.0, "session": 13}]), "SCALE"),  # 率が % で返っても同じ判定
        (game("loser", 4, [{"plays": 500, "d1": 0.04, "session": 2.5, "bounce60": 0.7}]), "KILL"),
        (game("middling", 4, [{"plays": 250, "d1": 0.14, "session": 7}]), "ITERATE"),
        (game("stuck", 20, [{"plays": 900, "d1": 0.14, "session": 7}], iterations=3), "KILL"),
        (game("no-retention-yet", 1, [{"plays": 150}]), "WAIT"),
    ]
    fail = 0
    for g, want in cases:
        got, why = decide_one(g, rules)
        ok = got == want
        fail += not ok
        print(f"{'OK ' if ok else 'NG '} {g['slug']:<18} → {got:<10} {why}")
    many = [game(f"w{i}", 9, [{"plays": 400, "d1": 0.2 + i / 100, "session": 12}]) for i in range(5)]
    res = decide_all(many, rules)
    n_scale = sum(o["decision"] == "SCALE" for o in res)
    ok = n_scale == rules["maxScale"] and sum(o["decision"] == "HOLD" for o in res) == 5 - rules["maxScale"]
    fail += not ok
    print(f"{'OK ' if ok else 'NG '} 伸ばす枠は上位 {rules['maxScale']} 本まで（SCALE {n_scale} 本）")
    print("selftest:", "すべて通過" if not fail else f"{fail} 件失敗")
    sys.exit(1 if fail else 0)


def main():
    for stream in (sys.stdout, sys.stderr):  # Windows の cp932 コンソール対策
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    for name, fn in [("status", cmd_status), ("next", cmd_next), ("metrics", cmd_metrics), ("report", cmd_report), ("selftest", cmd_selftest)]:
        sub.add_parser(name).set_defaults(fn=fn)
    p = sub.add_parser("add"); p.add_argument("slug"); p.set_defaults(fn=cmd_add)
    p = sub.add_parser("smoke"); p.add_argument("slug"); p.set_defaults(fn=cmd_smoke)
    p = sub.add_parser("publish"); p.add_argument("slug"); p.add_argument("--dry-run", action="store_true")
    p.add_argument("--public", action="store_true", help="体験を公開に切り替えた日として記録する"); p.set_defaults(fn=cmd_publish)
    p = sub.add_parser("decide"); p.add_argument("--no-save", action="store_true"); p.set_defaults(fn=cmd_decide)
    a = ap.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
