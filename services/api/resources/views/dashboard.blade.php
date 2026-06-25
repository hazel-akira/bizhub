<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>AkiraSaaS — Database Overview</title>
    <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>
    <style>
        :root {
            --bg: #0f1419;
            --surface: #1a2332;
            --surface2: #243044;
            --border: #2d3f56;
            --text: #e8edf4;
            --muted: #8b9cb3;
            --accent: #ff6b35;
            --accent2: #0d47a1;
            --green: #4caf50;
            --amber: #ffb74d;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Segoe UI', system-ui, sans-serif;
            background: var(--bg);
            color: var(--text);
            line-height: 1.5;
            min-height: 100vh;
        }
        .header {
            background: linear-gradient(135deg, var(--accent2), #1565c0);
            padding: 1.5rem 2rem;
            border-bottom: 3px solid var(--accent);
        }
        .header h1 { font-size: 1.6rem; font-weight: 700; }
        .header p { color: rgba(255,255,255,.85); margin-top: .35rem; font-size: .95rem; }
        .header .meta { margin-top: .75rem; font-size: .8rem; opacity: .8; }
        .container { max-width: 1280px; margin: 0 auto; padding: 1.5rem; }
        section { margin-bottom: 2rem; }
        h2 {
            font-size: 1.1rem;
            font-weight: 600;
            margin-bottom: 1rem;
            color: var(--accent);
            text-transform: uppercase;
            letter-spacing: .04em;
        }
        .diagram-wrap {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 1.5rem;
            overflow-x: auto;
        }
        .mermaid { display: flex; justify-content: center; }
        .flows {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 1rem;
        }
        .flow-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 1.25rem;
        }
        .flow-card h3 { font-size: 1rem; margin-bottom: .75rem; color: #fff; }
        .flow-card ol { padding-left: 1.2rem; font-size: .875rem; color: var(--muted); }
        .flow-card li { margin-bottom: .4rem; }
        .flow-card li strong { color: var(--text); font-weight: 600; }
        .table-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
            gap: 1rem;
        }
        .table-card {
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 12px;
            padding: 1rem 1.25rem;
            transition: border-color .15s;
        }
        .table-card:hover { border-color: var(--accent); }
        .table-card .top {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: .5rem;
        }
        .table-card h3 {
            font-family: ui-monospace, monospace;
            font-size: .95rem;
            color: #fff;
        }
        .badge {
            font-size: .75rem;
            font-weight: 700;
            padding: .2rem .55rem;
            border-radius: 999px;
            background: var(--surface2);
            color: var(--muted);
        }
        .badge.has-data { background: rgba(76,175,80,.2); color: var(--green); }
        .table-card p { font-size: .82rem; color: var(--muted); margin-bottom: .75rem; }
        .rels { font-size: .78rem; }
        .rels dt { color: var(--amber); font-weight: 600; margin-top: .4rem; }
        .rels dd { color: var(--muted); font-family: ui-monospace, monospace; margin-left: 0; }
        .api-link {
            display: inline-block;
            margin-top: 1rem;
            color: var(--accent);
            text-decoration: none;
            font-size: .875rem;
            font-weight: 600;
        }
        .api-link:hover { text-decoration: underline; }
        .legend {
            display: flex;
            flex-wrap: wrap;
            gap: 1rem;
            font-size: .8rem;
            color: var(--muted);
            margin-bottom: 1rem;
        }
        .legend span::before {
            content: '';
            display: inline-block;
            width: 10px; height: 10px;
            border-radius: 2px;
            margin-right: .4rem;
            vertical-align: middle;
        }
        .legend .core::before { background: var(--accent2); }
        .legend .pos::before { background: var(--green); }
        .legend .web::before { background: var(--accent); }
    </style>
</head>
<body>
    <header class="header">
        <h1>AkiraSaaS — Database Overview</h1>
        <p>How your PostgreSQL tables connect and what happens when data flows through the system.</p>
        <div class="meta">Database: <strong>{{ $database }}</strong> &nbsp;·&nbsp; API: <a href="/api/products" style="color:#ffb74d">/api/products</a></div>
    </header>

    <div class="container">
        <section>
            <h2>Entity relationships</h2>
            <div class="legend">
                <span class="core">Core — businesses, users, products</span>
                <span class="pos">POS — sales, purchases, expenses</span>
                <span class="web">Web — orders, M-Pesa</span>
            </div>
            <div class="diagram-wrap">
                <pre class="mermaid">{{ $mermaid }}</pre>
            </div>
        </section>

        <section>
            <h2>What happens when…</h2>
            <div class="flows">
                @foreach ($flows as $flow)
                    <article class="flow-card">
                        <h3>{{ $flow['title'] }}</h3>
                        <ol>
                            @foreach ($flow['steps'] as $step)
                                @php
                                    [$table, $rest] = array_pad(explode(' — ', $step, 2), 2, '');
                                @endphp
                                <li><strong>{{ $table }}</strong>@if($rest) — {{ $rest }}@endif</li>
                            @endforeach
                        </ol>
                    </article>
                @endforeach
            </div>
        </section>

        <section>
            <h2>Tables (live row counts)</h2>
            <div class="table-grid">
                @foreach ($tables as $table)
                    <article class="table-card">
                        <div class="top">
                            <h3>{{ $table['name'] }}</h3>
                            <span class="badge {{ $table['rows'] > 0 ? 'has-data' : '' }}">{{ $table['rows'] }} rows</span>
                        </div>
                        <p>{{ $table['description'] }}</p>
                        @if ($table['links_to'] || $table['linked_from'])
                            <dl class="rels">
                                @if ($table['links_to'])
                                    <dt>Points to →</dt>
                                    @foreach ($table['links_to'] as $link)
                                        <dd>{{ $link }}</dd>
                                    @endforeach
                                @endif
                                @if ($table['linked_from'])
                                    <dt>Referenced by ←</dt>
                                    @foreach (array_slice($table['linked_from'], 0, 4) as $link)
                                        <dd>{{ $link }}</dd>
                                    @endforeach
                                    @if (count($table['linked_from']) > 4)
                                        <dd>+{{ count($table['linked_from']) - 4 }} more</dd>
                                    @endif
                                @endif
                            </dl>
                        @endif
                    </article>
                @endforeach
            </div>
            <a class="api-link" href="/api/products">→ Test the JSON API</a>
        </section>
    </div>

    <script>
        mermaid.initialize({
            startOnLoad: true,
            theme: 'dark',
            er: { layoutDirection: 'TB' },
        });
    </script>
</body>
</html>
