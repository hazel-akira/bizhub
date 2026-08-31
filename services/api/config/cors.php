<?php

$localPatterns = [
    '#^http://localhost(:\d+)?$#',
    '#^http://127\.0\.0\.1(:\d+)?$#',
    '#^http://\[::1\](:\d+)?$#',
];

return [

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => array_filter(array_map(
        'trim',
        explode(',', env('FRONTEND_URL', 'http://localhost:3000'))
    )),

    // Flutter web dev uses random localhost ports; native Android/iOS ignore CORS.
    'allowed_origins_patterns' => $localPatterns,

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,

];
