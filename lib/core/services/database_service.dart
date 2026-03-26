import 'package:investflow/core/repositories/investment_repository.dart';
import 'package:investflow/core/repositories/message_repository.dart';
import 'package:investflow/core/repositories/milestone_repository.dart';
import 'package:investflow/core/repositories/project_repository.dart';
import 'package:investflow/core/repositories/user_repository.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  late final UserRepository userRepository;
  late final ProjectRepository projectRepository;
  late final InvestmentRepository investmentRepository;
  late final MilestoneRepository milestoneRepository;
  late final MessageRepository messageRepository;

  void initialize() {
    userRepository = UserRepository();
    projectRepository = ProjectRepository();
    investmentRepository = InvestmentRepository();
    milestoneRepository = MilestoneRepository();
    messageRepository = MessageRepository();
  }
}
