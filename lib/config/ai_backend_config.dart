/// Which backend drives the HHS Stage 1 onboarding chat ("Nova").
///
/// NOVA_CLAUDE_MIGRATION plan — this is the single, one-line rollback switch.
/// Flip [AiBackendConfig.provider] back to [AiBackend.voiceflow] to instantly
/// restore the old behavior; nothing else needs to change or be restored,
/// since ChatService/OnboardingService keep BOTH code paths intact and just
/// branch on this value.
enum AiBackend { voiceflow, claude }

class AiBackendConfig {
  /// Change this one line to roll back. The Voiceflow path (vfLaunchConversation
  /// / vfSendMessage / vfGetLatestMessages / flutterSyncOnboarding /
  /// flutterForgeFromTranscript) is untouched in the backend and in
  /// ChatService/OnboardingService, so switching back requires no other edit.
  static const AiBackend provider = AiBackend.claude;
}
