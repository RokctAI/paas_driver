/// Generalized operational states for any contract passing through the
/// orchestration engine (Order, Loan, Booking, Mission, ...).
enum ProcessingState {
  draft,
  submitted,
  accepted,
  processing,
  ready,
  dispatched,
  active,
  completed,
  failed,
  cancelled,
}

/// Represents any contract flowing through the orchestration engine.
///
/// Feature SDKs adapt their own domain objects to this interface (an order,
/// a loan application, a booking) without importing each other directly.
abstract class ProcessingContract {
  String get contractId;
  String get contractType;
  ProcessingState get currentState;
  Map<String, dynamic> get metadata;
  DateTime get updatedAt;

  /// Check payment state without direct financial coupling.
  bool get isPaid;
}

/// A simple immutable implementation for general or custom workflows.
class GenericContract implements ProcessingContract {
  @override
  final String contractId;
  @override
  final String contractType;
  @override
  final ProcessingState currentState;
  @override
  final Map<String, dynamic> metadata;
  @override
  final DateTime updatedAt;
  @override
  final bool isPaid;

  const GenericContract({
    required this.contractId,
    required this.contractType,
    required this.currentState,
    this.metadata = const {},
    required this.updatedAt,
    this.isPaid = false,
  });

  GenericContract copyWith({
    ProcessingState? currentState,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
    bool? isPaid,
  }) {
    return GenericContract(
      contractId: contractId,
      contractType: contractType,
      currentState: currentState ?? this.currentState,
      metadata: metadata ?? this.metadata,
      updatedAt: updatedAt ?? DateTime.now(),
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

/// Pure transition rules for the generalized lifecycle.
///
/// Kept free of I/O so feature SDKs and backends can share identical rules.
class ProcessingStateMachine {
  /// Allowed transitions. Anything not listed is rejected.
  static const Map<ProcessingState, Set<ProcessingState>> transitions = {
    ProcessingState.draft: {
      ProcessingState.submitted,
      ProcessingState.cancelled,
    },
    ProcessingState.submitted: {
      ProcessingState.accepted,
      ProcessingState.failed,
      ProcessingState.cancelled,
    },
    ProcessingState.accepted: {
      ProcessingState.processing,
      ProcessingState.cancelled,
    },
    ProcessingState.processing: {
      ProcessingState.ready,
      ProcessingState.active,
      ProcessingState.failed,
    },
    ProcessingState.ready: {
      ProcessingState.dispatched,
      ProcessingState.completed,
    },
    ProcessingState.dispatched: {
      ProcessingState.completed,
      ProcessingState.failed,
    },
    ProcessingState.active: {
      ProcessingState.completed,
      ProcessingState.cancelled,
    },
    ProcessingState.completed: {},
    ProcessingState.failed: {ProcessingState.submitted},
    ProcessingState.cancelled: {},
  };

  static bool canTransition(ProcessingState from, ProcessingState to) {
    return transitions[from]?.contains(to) ?? false;
  }

  /// Returns the reachable next states from [from].
  static Set<ProcessingState> nextStates(ProcessingState from) {
    return transitions[from] ?? const {};
  }

  static bool isTerminal(ProcessingState s) => nextStates(s).isEmpty;
}
