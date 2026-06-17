//holds the board display options: what to show on each card and how to sort
class BoardDisplaySettings {
  bool showPriority;
  bool showDescription;
  bool showDeadline;
  bool compact;
  String sortBy; // 'default', 'priority', 'deadline', 'title', 'newest'

  BoardDisplaySettings({
    this.showPriority = true,
    this.showDescription = true,
    this.showDeadline = true,
    this.compact = false,
    this.sortBy = 'default',
  });

  //make a copy so the settings sheet can edit without changing the original
  BoardDisplaySettings copy() {
    return BoardDisplaySettings(
      showPriority: showPriority,
      showDescription: showDescription,
      showDeadline: showDeadline,
      compact: compact,
      sortBy: sortBy,
    );
  }
}
