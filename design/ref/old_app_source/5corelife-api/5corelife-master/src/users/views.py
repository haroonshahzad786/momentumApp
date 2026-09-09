"""Users views."""

# Django
from django.shortcuts import get_object_or_404

# Django REST Framework
from rest_framework import mixins, serializers, status, viewsets
from rest_framework.authtoken.models import Token
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

# 5CoreLife
from users.models import User
from users.permissions import IsAccountOwner
from users.serializers import (
    AccountVerificationSerializer,
    CodeRedemptionSerializer,
    ExportCSVRenderer,
    ForgotPasswordSerializer,
    LeaderboardSerializer,
    PasswordResetSerializer,
    UserLoginSerializer,
    UserMantraSerializer,
    UserModelSerializer,
    UserSignUpSerializer,
)


class UserViewSet(mixins.RetrieveModelMixin, mixins.UpdateModelMixin, viewsets.GenericViewSet):
    """User view set.

    Handle login, logout and account management.
    """

    queryset = User.objects.all()
    lookup_field = 'username'

    def get_renderers(self):
        """
        Instantiates and returns the list of renderers that this view can use.
        """
        if self.action == 'export_csv':
            return [ExportCSVRenderer()]
        return [renderer() for renderer in self.renderer_classes]

    def get_permissions(self):
        """Assign permission based on action."""
        if self.action in ['login', 'forgot_password', 'password_reset', 'signup']:
            permissions = [AllowAny]
        elif self.action in [
            'retrieve',
            'update',
            'partial_update',
            'logout',
            'mantra',
            'abort_journey',
            'pause_journey',
        ]:
            permissions = [IsAuthenticated, IsAccountOwner]
        else:
            permissions = [IsAuthenticated]
        return [p() for p in permissions]

    def get_serializer_class(self):
        """Return serializer based on action."""
        action_mappings = {
            'signup': UserSignUpSerializer,
            'login': UserLoginSerializer,
            'forgot_password': ForgotPasswordSerializer,
            'password_reset': PasswordResetSerializer,
            'mantra': UserMantraSerializer,
            'verify': AccountVerificationSerializer,
            'code_redemption': CodeRedemptionSerializer,
            'leaderboard': LeaderboardSerializer,
        }
        return action_mappings.get(self.action, UserModelSerializer)

    def get_object(self):
        queryset = self.get_queryset()
        obj = get_object_or_404(queryset, username=self.request.user.username)
        return obj

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response(UserModelSerializer(user).data)

    @action(detail=False, methods=['post'])
    def signup(self, request):
        """User signup."""
        serializer_class = self.get_serializer_class()
        serializer = serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        data = UserModelSerializer(user).data
        return Response(data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['post'])
    def login(self, request):
        """User login."""
        serializer_class = self.get_serializer_class()
        serializer = serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        user, token = serializer.save()
        data = {'user': UserModelSerializer(user).data, 'access_token': token}
        return Response(data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'])
    def logout(self, request):
        """User logout."""
        user = self.request.user
        Token.objects.filter(user=user).delete()
        data = {
            'response': 'User logout success.',
        }
        return Response(data, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'])
    def verify(self, request):
        """Account verification"""
        serializer = AccountVerificationSerializer(
            data=request.data, context={'request': request, 'user': request.user}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        data = {'message': 'Congratulations, your account was validated!'}
        return Response(data, status=status.HTTP_200_OK)

    @action(url_path='forgot-password', detail=False, methods=['post'])
    def forgot_password(self, request):
        """Password forgot by user."""
        serializer_class = self.get_serializer_class()
        serializer = serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        data = {'response': 'Email sent.'}
        return Response(data, status=status.HTTP_200_OK)

    @action(url_path='password-reset', detail=False, methods=['post'])
    def password_reset(self, request):
        """Password reset based on code sent via email."""
        serializer_class = self.get_serializer_class()
        serializer = serializer_class(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        data = {'response': 'Password updated.'}
        return Response(data, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get', 'put'])
    def mantra(self, request):
        """Get or update mantra."""
        serializer_class = self.get_serializer_class()
        if request.method == 'GET':
            serializer = serializer_class(request.user)
            mantra = serializer.data
            return Response(mantra, status=status.HTTP_200_OK)

        elif request.method == 'PUT':
            if 'mantra' not in request.data:
                raise serializers.ValidationError('Mantra missing')

            if not request.data['mantra']:
                raise serializers.ValidationError('Mantra is required.')
            request.user.mantra = request.data['mantra']
            request.user.save()
            serializer = serializer_class(request.user)
            return Response(serializer.data)

    @action(detail=False, methods=['post'], url_path='abort-journey')
    def abort_journey(self, request):
        """Abort current journey."""
        serializer_class = self.get_serializer_class()
        user = self.get_object()
        user.user_profile.days_in_journey = 0
        user.user_profile.in_journey = False
        user.user_profile.save()
        data = serializer_class(user).data
        return Response(data, status=status.HTTP_200_OK)

    @action(detail=False, methods=['post'], url_path='pause-journey')
    def pause_journey(self, request):
        """Pause current journey."""
        serializer_class = self.get_serializer_class()
        user = self.get_object()
        user.user_profile.pause = not user.user_profile.pause
        user.user_profile.save()
        data = serializer_class(user).data
        return Response(data, status=status.HTTP_200_OK)

    @action(detail=False, methods=['GET'], url_path='export-csv')
    def export_csv(self, request, *args, **kwargs):
        user = request.user
        content = ExportCSVRenderer().get_data(user)
        return Response(content)

    @action(detail=False, methods=['POST'], url_path='code-redemption')
    def code_redemption(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        code = serializer.save()
        data = {'code': code.code, 'redeemed_by': code.redeemed_by.username, 'claimed_date': code.claimed_date}
        return Response(data, status=status.HTTP_200_OK)

    @action(detail=False, methods=['GET'], url_path='leaderboard')
    def leaderboard(self, request, *args, **kwargs):
        queryset = self.queryset.order_by('-user_profile__score')
        users = queryset[:20]
        if request.user not in users:
            users = queryset.exclude(pk=queryset[19].pk)
            users |= queryset.filter(pk=request.user.pk)
        serializer = self.get_serializer(users, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
