enum HabitFrequency {
  once(1, 'Once a week'),
  twice(2, 'Twice a week'),
  threeTimes(3, 'Three times a week'),
  fourTimes(4, 'Four times a week'),
  fiveTimes(5, 'Five times a week'),
  sixTimes(6, 'Six times a week'),
  daily(7, 'Every day');

  final int timesPerWeek;
  final String displayName;

  const HabitFrequency(this.timesPerWeek, this.displayName);
}
