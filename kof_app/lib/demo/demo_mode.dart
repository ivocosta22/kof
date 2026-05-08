/// Set to true when the app is built / run with --dart-define=DEMO_MODE=true.
/// All demo-mode guards in the codebase read this constant; dead-code
/// elimination removes the branches entirely in a normal production build.
const kDemoMode = bool.fromEnvironment('DEMO_MODE');
