import 'package:investflow/core/repositories/investment_repository.dart';
import 'package:investflow/core/repositories/message_repository.dart';
import 'package:investflow/core/repositories/milestone_repository.dart';
import 'package:investflow/core/repositories/project_repository.dart';
import 'package:investflow/core/repositories/user_repository.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  UserRepository? _userRepository;
  ProjectRepository? _projectRepository;
  InvestmentRepository? _investmentRepository;
  MilestoneRepository? _milestoneRepository;
  MessageRepository? _messageRepository;

  // Getters
  UserRepository get userRepository {
    _userRepository ??= UserRepository();
    return _userRepository!;
  }

  ProjectRepository get projectRepository {
    _projectRepository ??= ProjectRepository();
    return _projectRepository!;
  }

  InvestmentRepository get investmentRepository {
    _investmentRepository ??= InvestmentRepository();
    return _investmentRepository!;
  }

  MilestoneRepository get milestoneRepository {
    _milestoneRepository ??= MilestoneRepository();
    return _milestoneRepository!;
  }

  MessageRepository get messageRepository {
    _messageRepository ??= MessageRepository();
    return _messageRepository!;
  }

  void initialize() {
    userRepository; // Trigger lazy init
    projectRepository;
    investmentRepository;
    milestoneRepository;
    messageRepository;
  }
}
