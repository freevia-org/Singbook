/// Shared font families for the app theme and the appearance menu previews.
///
/// Keep these IDs stable: they are stored in settings and library backups.
String verseFontFamily(String id) => switch (id) {
  'serif' => 'serif',
  'mono' => 'monospace',
  'lora' => 'Lora',
  'nunito' => 'Nunito',
  'sourceSans' => 'Source Sans 3',
  _ => 'sans-serif',
};
