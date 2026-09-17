-- Pure validation tests; no POST, feedback creation, credential access or DML.
set define off
set serveroutput on
declare
  l_count number := 0;
  l_json json_object_t;
  c_key constant varchar2(100) := 'afma-apex-feedback-acceptance-fixture';
  procedure expect(p_expected boolean, p_label varchar2) is
    l_actual boolean;
  begin
    l_actual := afma_ai_hub_forwarder.acknowledgement_is_valid(l_json.to_clob, c_key);
    if l_actual is null or l_actual <> p_expected then
      raise_application_error(-20191, 'FAIL: ' || p_label);
    end if;
    l_count := l_count + 1;
  end;
  procedure valid_response is
  begin
    l_json := json_object_t();
    l_json.put('status', 'accepted');
    l_json.put('projectKey', 'caab');
    l_json.put('idempotencyKey', c_key);
    l_json.put('feedbackKey', '12345');
    l_json.put('taskAction', 'NONE');
    l_json.put('publicResponse', 'Controlled contract fixture only.');
  end;
begin
  valid_response;
  expect(true, 'Response-only acknowledgement');
  l_json.put('taskKey', 'caab-015');
  l_json.remove('feedbackKey');
  l_json.remove('publicResponse');
  l_json.remove('taskAction');
  expect(true, 'Task-backed acknowledgement can resolve source key separately');
  l_json.remove('taskKey');
  expect(false, 'Identifierless success must remain retryable');
  valid_response;
  l_json.put('projectKey', 'afma');
  expect(false, 'Historical project rejected');
  valid_response;
  l_json.put('idempotencyKey', 'different-source-record');
  expect(false, 'Different source identity rejected');
  valid_response;
  l_json.put('status', 'failed');
  expect(false, 'Unaccepted status rejected');
  valid_response;
  l_json.put('taskKey', 'other-project-015');
  expect(false, 'Foreign task key rejected');
  valid_response;
  l_json.put('feedbackKey', '../another-record');
  expect(false, 'Invalid feedback key rejected');
  valid_response;
  l_json.put('feedbackKey', false);
  expect(false, 'Boolean feedback key rejected');
  valid_response;
  l_json.put('feedbackKey', 'not-a-record');
  expect(false, 'Nonnumeric feedback key rejected');
  valid_response;
  l_json.put('feedbackKey', '0');
  expect(false, 'Nonpositive feedback key rejected');
  valid_response;
  l_json.remove('publicResponse');
  expect(false, 'Response-only requires a public response');
  valid_response;
  l_json.put('taskAction', 'CREATE');
  expect(false, 'Task action requires task identity');
  valid_response;
  l_json.put('feedbackKey', ' ');
  expect(false, 'Whitespace identifier rejected');
  l_json := json_object_t();
  expect(false, 'Empty response rejected');
  if afma_ai_hub_forwarder.acknowledgement_is_valid('not json', c_key) then
    raise_application_error(-20191, 'FAIL: Malformed response accepted');
  end if;
  l_count := l_count + 1;
  dbms_output.put_line('FEEDBACK CONTRACT PASSED: ' || l_count || ' checks; no external requests or writes.');
end;
/
