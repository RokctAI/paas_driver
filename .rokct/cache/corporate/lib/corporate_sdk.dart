library corporate_sdk;

// Import concrete files via package:corporate_sdk/src/...
export 'src/common/di/corporate_di.dart';
// Policy / terms pages — host apps wire these into EmbeddedWidgets
// (auth's login footer links call policyPage()/termPage()).
export 'src/common/presentation/pages/policy_term/policy_page.dart';
export 'src/common/presentation/pages/policy_term/term_page.dart';
