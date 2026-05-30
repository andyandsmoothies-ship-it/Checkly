UPDATE templates SET type = 'training' WHERE type = 'Training';
UPDATE templates SET type = 'general' WHERE type = 'General';
UPDATE templates SET type = 'task force' WHERE type = 'Taskforce' OR type = 'task_force';
