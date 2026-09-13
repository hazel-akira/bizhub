<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Support — Akira Flow</title>
    <style>
        :root { --green:#2D5A3D; --orange:#C75B12; --text:#1a1a1a; --muted:#5c5c5c; }
        body { font-family: system-ui, sans-serif; max-width: 720px; margin: 0 auto; padding: 32px 20px 64px; color: var(--text); line-height: 1.6; }
        h1 { color: var(--green); }
        a { color: var(--orange); }
    </style>
</head>
<body>
    <h1>Akira Flow support</h1>
    <p>Need help with the Android app, Google Sign-In, or M-Pesa till setup?</p>
    <p>Email <a href="mailto:{{ config('mail.from.address') }}">{{ config('mail.from.address') }}</a> and include:</p>
    <ul>
        <li>The Google account email you use in the app</li>
        <li>Your business name</li>
        <li>What you were doing when the problem happened</li>
    </ul>
    <p><a href="/privacy">Privacy policy</a></p>
</body>
</html>
