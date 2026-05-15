import { ActionPanel, Action, Form, showToast, Toast, open, popToRoot } from "@raycast/api";
import { useEffect, useState } from "react";
import { readFileSync } from "fs";
import { homedir } from "os";
import { join } from "path";

interface Task {
  isCompleted: boolean;
}
interface Sticky {
  id: string;
  title: string;
  tasks: Task[];
}
interface StickyFile {
  schemaVersion: number;
  stickies: Sticky[];
}

const STICKY_PATH = join(
  homedir(),
  "Library/Containers/com.stickytodos.app/Data/Library/Application Support/Sticky/stickies.json",
);

export default function Command() {
  const [stickies, setStickies] = useState<Sticky[]>([]);
  const [selectedID, setSelectedID] = useState<string>("");
  const [text, setText] = useState("");
  const [loadError, setLoadError] = useState(false);

  useEffect(() => {
    try {
      const raw = readFileSync(STICKY_PATH, "utf-8");
      const data: StickyFile = JSON.parse(raw);
      setStickies(data.stickies);
      if (data.stickies.length > 0) setSelectedID(data.stickies[0].id);
    } catch (e) {
      setLoadError(true);
      showToast({
        style: Toast.Style.Failure,
        title: "Couldn't read Sticky data",
        message: "Has Sticky been launched at least once?",
      });
    }
  }, []);

  async function handleSubmit() {
    const trimmed = text.trim();
    if (!selectedID || !trimmed) {
      showToast({
        style: Toast.Style.Failure,
        title: "Pick a sticky and enter task text",
      });
      return;
    }
    const url = `sticky://add?stickyID=${selectedID}&text=${encodeURIComponent(trimmed)}`;
    await open(url);
    await showToast({ style: Toast.Style.Success, title: "Task added" });
    await popToRoot();
  }

  if (loadError) {
    return (
      <Form>
        <Form.Description text="Couldn't load stickies. Make sure Sticky has run at least once, then try again." />
      </Form>
    );
  }

  return (
    <Form
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Add Task" onSubmit={handleSubmit} />
        </ActionPanel>
      }
    >
      <Form.Dropdown id="sticky" title="Sticky" value={selectedID} onChange={setSelectedID}>
        {stickies.map((s) => {
          const remaining = s.tasks.filter((t) => !t.isCompleted).length;
          return (
            <Form.Dropdown.Item
              key={s.id}
              value={s.id}
              title={`${s.title} — ${remaining}/${s.tasks.length}`}
            />
          );
        })}
      </Form.Dropdown>
      <Form.TextArea
        id="text"
        title="Task"
        value={text}
        onChange={setText}
        placeholder="Buy milk"
        autoFocus
      />
    </Form>
  );
}
