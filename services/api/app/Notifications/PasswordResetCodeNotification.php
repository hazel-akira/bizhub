<?php

namespace App\Notifications;

use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class PasswordResetCodeNotification extends Notification
{
    public function __construct(public readonly string $code) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $name = trim((string) ($notifiable->name ?? ''));

        return (new MailMessage)
            ->subject('Your Akira Flow password reset code')
            ->greeting($name !== '' ? "Hello {$name}," : 'Hello,')
            ->line('Use this 6-digit code in the app to reset your password. It expires in 60 minutes.')
            ->line("Reset code: {$this->code}")
            ->line('If you did not ask for this, you can ignore this email.');
    }
}
