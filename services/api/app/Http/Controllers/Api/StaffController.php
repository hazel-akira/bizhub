<?php

namespace App\Http\Controllers\Api;

use App\Enums\BusinessType;
use App\Http\Controllers\Concerns\RespondsWithJson;
use App\Http\Controllers\Controller;
use App\Http\Requests\StoreStaffRequest;
use App\Http\Requests\UpdateStaffRequest;
use App\Models\User;
use App\Support\StaffAccess;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StaffController extends Controller
{
    use RespondsWithJson;

    public function roles(): JsonResponse
    {
        return $this->success(StaffAccess::catalog());
    }

    public function index(Request $request): JsonResponse
    {
        $staff = User::query()
            ->where('business_id', $request->user()->business_id)
            ->orderBy('name')
            ->get()
            ->map(fn (User $user) => $this->format($user));

        return $this->success($staff);
    }

    public function store(StoreStaffRequest $request): JsonResponse
    {
        $validated = $request->validated();
        StaffAccess::assertCompatible($validated['roles']);
        $this->assertCanAssignOwner($request->user(), $validated['roles']);

        $user = new User;
        $user->business_id = $request->user()->business_id;
        $user->name = $validated['name'];
        $user->email = $validated['email'];
        $user->password = $validated['password'];
        $user->is_active = true;
        $user->syncStaffRoles($validated['roles']);
        $user->save();

        return $this->success($this->format($user->load('business')), 201, 'Staff member created');
    }

    public function update(UpdateStaffRequest $request, User $staff): JsonResponse
    {
        $this->authorizeStaff($request, $staff);
        $validated = $request->validated();
        $actor = $request->user();

        if (isset($validated['roles'])) {
            StaffAccess::assertCompatible($validated['roles']);
            $this->assertCanAssignOwner($actor, $validated['roles']);
            $this->assertNotLastOwnerDemotion($staff, $validated['roles']);
            $staff->syncStaffRoles($validated['roles']);
        }

        if (array_key_exists('name', $validated)) {
            $staff->name = $validated['name'];
        }
        if (array_key_exists('email', $validated)) {
            $staff->email = $validated['email'];
        }
        if (! empty($validated['password'])) {
            $staff->password = $validated['password'];
        }
        if (array_key_exists('is_active', $validated)) {
            $this->assertNotLastOwnerDeactivation($actor, $staff, (bool) $validated['is_active']);
            $staff->is_active = (bool) $validated['is_active'];
        }

        $staff->save();

        return $this->success($this->format($staff->fresh()));
    }

    public function destroy(Request $request, User $staff): JsonResponse
    {
        $this->authorizeStaff($request, $staff);
        $this->assertNotLastOwnerDeactivation($request->user(), $staff, false);
        $staff->is_active = false;
        $staff->save();

        return $this->success($this->format($staff->fresh()), 200, 'Staff member deactivated');
    }

    private function authorizeStaff(Request $request, User $staff): void
    {
        abort_if(
            $staff->business_id !== $request->user()->business_id,
            404,
            'Staff member not found'
        );
    }

    /** @param  list<mixed>  $roles */
    private function assertCanAssignOwner(User $actor, array $roles): void
    {
        $normalized = StaffAccess::normalize($roles);
        if (in_array(StaffAccess::OWNER, $normalized, true) && ! $actor->isOwner()) {
            abort(403, 'Only an owner can assign admin access.');
        }
    }

    /** @param  list<mixed>  $roles */
    private function assertNotLastOwnerDemotion(User $staff, array $roles): void
    {
        $next = StaffAccess::normalize($roles);
        if ($staff->isOwner() && ! in_array(StaffAccess::OWNER, $next, true) && $this->activeOwnerCount($staff) <= 1) {
            abort(422, 'Keep at least one active owner on the business.');
        }
    }

    private function assertNotLastOwnerDeactivation(User $actor, User $staff, bool $willBeActive): void
    {
        if ($staff->id === $actor->id && $willBeActive === false) {
            abort(422, 'You cannot deactivate your own account.');
        }

        if ($staff->isOwner() && $willBeActive === false && $this->activeOwnerCount($staff) <= 1) {
            abort(422, 'Keep at least one active owner on the business.');
        }
    }

    private function activeOwnerCount(User $staff): int
    {
        return User::query()
            ->where('business_id', $staff->business_id)
            ->where('is_active', true)
            ->get()
            ->filter(fn (User $user) => $user->isOwner())
            ->count();
    }

    private function format(User $user): array
    {
        $type = BusinessType::tryFromString($user->business?->business_type);
        $roles = $user->staffRoles();

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => StaffAccess::primaryRole($roles),
            'roles' => $roles,
            'permissions' => StaffAccess::permissionsFor($roles),
            'business_id' => $user->business_id,
            'business_name' => $user->business?->name,
            'business_type' => $type?->value ?? $user->business?->business_type,
            'is_active' => (bool) $user->is_active,
        ];
    }
}
