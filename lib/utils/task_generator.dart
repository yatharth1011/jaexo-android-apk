import 'package:uuid/uuid.dart';
import '../models/profile.dart';
import '../data/schedule_2026.dart';

class TaskGenerator {
  static const _uuid = Uuid();

  static List<TaskItem> generateDailyTasks(DateTime date) {
    final tasks = <TaskItem>[];
    final dayNum = date.day;
    final scheduleItem = Schedule2026.getItemForDate(date);

    TaskItem createTask(String text, String tag, String mode) {
      return TaskItem(
        id: _uuid.v4(),
        text: text,
        tag: tag,
        mode: mode,
        createdAt: date,
      );
    }

    final mathBook = dayNum % 3 == 0
        ? 'Yellow Book: Algebra'
        : dayNum % 3 == 1
            ? 'Sameer Bansal: Calculus'
            : 'Pink Book: Coord/Vector';

    if (scheduleItem == null) {
      tasks.add(createTask('PYQs - Training', 'JEEADV', 'training'));
      tasks.add(createTask('PYQs - Online Test', 'JEEADV', 'online_test'));
      tasks.add(createTask('PYQs - Offline', 'JEEADV', 'offline'));
      tasks.add(createTask('PYQs - Focus', 'JEEADV', 'focus'));
      return tasks;
    }

    if (scheduleItem.type == 'BOARD_EXAM') {
      tasks.add(createTask('CBSE EXAM: ${scheduleItem.event}', 'EXAM', 'offline'));
      return tasks;
    }

    if (scheduleItem.type == 'HEAVY') {
      tasks.add(createTask('EVENT: ${scheduleItem.event}', 'TEST', 'offline'));
      tasks.add(createTask('Analysis & Mistake Audit', 'AUDIT', 'focus'));
      return tasks;
    }

    if (scheduleItem.type == 'BOARD_PREP') {
      final subject = scheduleItem.event.split(':')[1].trim();
      tasks.add(createTask('Board Prep: $subject', 'BOARD', 'focus'));

      if (scheduleItem.event.contains('IOC')) {
        tasks.add(createTask('VKJ: IOC Selected Qs', 'IOC', 'training'));
      }
      if (scheduleItem.event.contains('OC')) {
        tasks.add(createTask('SKM-JA: Organic', 'OC', 'training'));
      }
      if (scheduleItem.event.contains('PC')) {
        tasks.add(createTask('NK-JA: Physical', 'PC', 'training'));
      }
      if (scheduleItem.event.contains('Physics') || scheduleItem.event.contains('PHY')) {
        tasks.add(createTask('Physics: Allen GR Package / HCV', 'PHY', 'training'));
      }
      if (scheduleItem.event.contains('Math')) {
        tasks.add(createTask(mathBook, 'MATH', 'training'));
      }
      return tasks;
    }

    if (scheduleItem.type == 'TEST') {
      tasks.add(createTask('${scheduleItem.event} (Paper Attempt)', 'TEST', 'offline'));
      tasks.add(createTask('Thorough Analysis', 'AUDIT', 'focus'));

      if (scheduleItem.event.contains('Math')) {
        tasks.add(createTask(mathBook, 'MATH', 'training'));
      }
      if (scheduleItem.event.contains('Physics') || scheduleItem.event.contains('PHY')) {
        tasks.add(createTask('Physics: Allen GR Package / HCV', 'PHY', 'training'));
      }
      if (scheduleItem.event.contains('IOC')) {
        tasks.add(createTask('VKJ: IOC', 'IOC', 'training'));
      }
      if (scheduleItem.event.contains('OC')) {
        tasks.add(createTask('SKM-JA: Organic', 'OC', 'training'));
      }
      if (scheduleItem.event.contains('PC')) {
        tasks.add(createTask('NK-JA: Physical', 'PC', 'training'));
      }
      return tasks;
    }

    if (scheduleItem.type == 'GRIND' || scheduleItem.type == 'PREP') {
      if (scheduleItem.type == 'GRIND' &&
          !scheduleItem.event.contains(':') &&
          !scheduleItem.event.contains('/')) {
        tasks.add(createTask(mathBook, 'MATH', 'training'));
        tasks.add(createTask('Physics: Allen GR Package / HCV', 'PHY', 'training'));
        tasks.add(createTask('NK-JA: Physical Chem', 'PC', 'training'));
        tasks.add(createTask('SKM-JA: Organic', 'OC', 'training'));
        tasks.add(createTask('VKJ: IOC', 'IOC', 'training'));
      } else {
        if (scheduleItem.event.contains('Math')) {
          tasks.add(createTask(mathBook, 'MATH', 'training'));
        }
        if (scheduleItem.event.contains('Physics') || scheduleItem.event.contains('PHY')) {
          tasks.add(createTask('Physics: Allen GR Package / HCV', 'PHY', 'training'));
        }
        if (scheduleItem.event.contains('IOC')) {
          tasks.add(createTask('VKJ: IOC', 'IOC', 'training'));
        }
        if (scheduleItem.event.contains('OC')) {
          tasks.add(createTask('SKM-JA: Organic', 'OC', 'training'));
        }
        if (scheduleItem.event.contains('PC')) {
          tasks.add(createTask('NK-JA: Physical', 'PC', 'training'));
        }
      }
    }

    return tasks;
  }
}
