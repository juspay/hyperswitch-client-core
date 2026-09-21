import { errorResult, messageOf } from '../core/results';
import { hostBridge } from './bridge';
import type { HostBridge, RawCommand } from './bridge';
import { isElementType } from './descriptor';
import { getForm } from './forms';
import { FormEvent } from './protocol';
import type { CommandResultPayload, FieldCommandName } from './protocol';

const FIELD_COMMANDS: readonly string[] = ['focus', 'blur', 'clear'];

type Outcome = Omit<CommandResultPayload, 'commandId' | 'name'>;

/* ok says whether the command ran. A tokenize that the vault refused still
   ran: its refusal is the result, as it is for in-process callers. */
async function run(command: RawCommand): Promise<Outcome> {
  const form = getForm(command.formId);

  if (command.name === 'tokenize') {
    const result = form?.instance
      ? await form.instance.tokenize(command.providerData)
      : errorResult(
          undefined,
          'incomplete_field_set',
          `No form "${command.formId}" is open.`
        );
    return { ok: true, result };
  }

  if (FIELD_COMMANDS.includes(command.name)) {
    const elementType = command.elementType;
    const field = isElementType(elementType)
      ? form?.fields[elementType]?.()
      : undefined;
    if (!field) {
      return {
        ok: false,
        message: `Form "${command.formId}" has no "${String(elementType)}" field mounted.`,
      };
    }
    field[command.name as FieldCommandName]();
    return { ok: true };
  }

  return { ok: false, message: `Unknown command "${command.name}".` };
}

/* Started once per engine, from the entry file: commands address a form by id,
   so no screen has to be listening for them. */
export function startCommands(bridge: HostBridge = hostBridge): () => void {
  return bridge.onCommand((command) => {
    const reply = (outcome: Outcome) =>
      bridge.emitForm(command.rootTag, FormEvent.CommandResult, {
        commandId: command.commandId,
        name: command.name,
        ...outcome,
      });

    run(command).then(reply, (error: unknown) =>
      reply({ ok: false, message: messageOf(error) })
    );
  });
}
