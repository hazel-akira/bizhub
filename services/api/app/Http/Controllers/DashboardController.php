<?php

namespace App\Http\Controllers;

use App\Services\SchemaOverviewService;

class DashboardController extends Controller
{
    public function __construct(private readonly SchemaOverviewService $schema) {}

    public function index()
    {
        return view('dashboard', $this->schema->overview());
    }
}
