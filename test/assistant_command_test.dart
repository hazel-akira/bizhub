import 'package:akira_bites/services/assistant_command.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spoken phrases map to the right assistant intent', () {
    expect(matchAssistantCommand('today summary'), AssistantIntent.todaySummary);
    expect(matchAssistantCommand("what's my profit?"), AssistantIntent.profit);
    expect(matchAssistantCommand('who owes me'), AssistantIntent.whoOwes);
    expect(matchAssistantCommand('unpaid customers'), AssistantIntent.whoOwes);
    expect(matchAssistantCommand('how much is unpaid'), AssistantIntent.unpaidTotal);
    expect(matchAssistantCommand('sales today'), AssistantIntent.revenue);
    expect(matchAssistantCommand('best seller this week'), AssistantIntent.bestSelling);
    expect(matchAssistantCommand('how many sold today'), AssistantIntent.unitsSold);
    expect(matchAssistantCommand('hello there'), AssistantIntent.unknown);
  });

  test('a more specific debt question is not swallowed by summary', () {
    expect(
      matchAssistantCommand('who owes on the summary'),
      AssistantIntent.whoOwes,
    );
  });
}