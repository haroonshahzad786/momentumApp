"""Admin Users."""

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from django.utils.translation import gettext_lazy as _
from users.models import User, UserDevice, PushNotification, EmailNotification, UserProfile, RedemptionCode, CodeFile


class UserDeviceInline(admin.TabularInline):
    """UserDevice Inline."""

    model = UserDevice
    extra = 0


class UserProfileAdmin(admin.StackedInline):
    model = UserProfile
    extra = 0


@admin.register(User)
class CustomUserAdmin(UserAdmin):
    """Override User model admin."""

    fieldsets = (
        (None, {'fields': ('username', 'password')}),
        (_('Personal info'), {'fields': ('first_name', 'last_name', 'email')}),
        (_('App info'), {'fields': ('mantra', 'tz_zone')}),
        (
            _('Permissions'),
            {
                'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
            },
        ),
        (_('Important dates'), {'fields': ('last_login', 'date_joined')}),
    )
    add_fieldsets = (
        (
            None,
            {
                'classes': ('wide',),
                'fields': ('username', 'password1', 'password2'),
            },
        ),
    )
    list_display = ('email', 'username', 'first_name', 'last_name', 'is_staff', 'created')
    list_filter = ('is_staff', 'created')
    inlines = (
        UserProfileAdmin,
        UserDeviceInline,
    )


@admin.register(UserDevice)
class UserDeviceAdmin(admin.ModelAdmin):
    """PushNotification Admin."""

    list_display = ('user', 'registration_id')
    search_fields = ('user__email', 'registration_id')


@admin.register(PushNotification)
class PushNotificationAdmin(admin.ModelAdmin):
    """PushNotification Admin."""

    list_display = ('title', 'status', 'delivery_datetime', 'user_device')
    list_filter = ('created',)
    autocomplete_fields = ('user_device',)
    readonly_fields = ('request_body', 'request_response')
    search_fields = ('title', 'user_device__user__username')


@admin.register(EmailNotification)
class EmailNotificationAdmin(admin.ModelAdmin):
    """EmailNotification Admin."""

    list_display = ('subject', 'status')
    readonly_fields = ('request_body', 'request_response')


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    """UserProfile Admin."""

    search_fields = (
        'user__email',
        'user__username',
    )
    list_display = ('user', 'score', 'armor', 'destination', 'notifications', 'pause')
    list_filter = ('pause',)

    def armor(self, obj):
        improvement_user = obj.user.improvements.filter(improvement__improvement_type='ARMOR', equipped=True).first()
        return improvement_user.improvement.name if improvement_user else '-'

    def destination(self, obj):
        return obj.get_actual_destination().destination if obj.get_actual_destination() else '-'


@admin.register(CodeFile)
class CodeFileAdmin(admin.ModelAdmin):
    """CodeFile Admin."""

    list_display = ["file", "proccessed"]


@admin.register(RedemptionCode)
class RedemptionCodedmin(admin.ModelAdmin):
    """RedemptionCode Admin."""

    list_display = ["code", "redeemed_by", "claimed_date"]
    search_fields = ["redeemed_by__username"]
