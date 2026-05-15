import {
  ActionPanel,
  Action,
  Form,
  List,
  showToast,
  Toast,
  open,
  popToRoot,
  Icon,
  Color,
  useNavigation,
} from "@raycast/api";
import { useEffect, useState } from "react";
import { readFileSync } from "fs";
import { homedir } from "os";
import { join } from "path";

// MARK: - Types

interface Task {
  id: string;
  isCompleted: boolean;
  title: string;
}

interface StickyColorThemeRaw {
  preset?: { _0: string };
  custom?: { _0: string };
}

interface Sticky {
  id: string;
  title: string;
  tasks: Task[];
  colorTheme?: StickyColorThemeRaw;
}

interface StickyFile {
  schemaVersion: number;
  stickies: Sticky[];
}

// MARK: - Constants

const STICKY_PATH = join(
  homedir(),
  "Library/Containers/com.stickytodos.app/Data/Library/Application Support/Sticky/stickies.json",
);

// Map preset color names to Raycast Color tokens for icons + accents
const PRESET_TO_RAYCAST: Record<string, Color> = {
  yellow: Color.Yellow,
  pink: Color.Magenta,
  green: Color.Green,
  blue: Color.Blue,
  purple: Color.Purple,
  orange: Color.Orange,
};

// Colored emoji per preset — used to theme the form view (which Raycast doesn't
// let us color directly, so we use coloured circle emojis as visual accents)
const PRESET_EMOJI: Record<string, string> = {
  yellow: "🟡",
  pink: "🩷",
  green: "🟢",
  blue: "🔵",
  purple: "🟣",
  orange: "🟠",
};

const CHEEKY_PLACEHOLDERS = [
  "Touch grass",
  "Reply to that email from 3 weeks ago",
  "Drink water (you haven't today)",
  "Stop scrolling",
  "Call mum",
  "Take out the bins before it gets feral",
  "Do the thing you've been avoiding",
  "Hydrate, peasant",
  "Wash that one mug",
  "Cancel that subscription you forgot about",
  "Conquer the world",
  "Become slightly less of a goblin",
  "Be a person today",
  "Survive Monday",
  "Open the post pile",
  "Tidy the desk (lol)",
  "Make the bed (maybe)",
  "Take a deep breath",
  "Email back finally",
  "Romanticise the chore",
  "Pretend to be productive",
  "Slay the dragon",
  "Pet a dog",
  "Plan world domination",
  "Reduce email backlog (good luck)",
  "Read that book you bought 2 years ago",
  "Stop being a gremlin",
  "Do laundry (it's been a week)",
  "Stretch like you mean it",
  "Touch the sky",
];

// MARK: - Helpers

function randomPlaceholder(): string {
  return CHEEKY_PLACEHOLDERS[Math.floor(Math.random() * CHEEKY_PLACEHOLDERS.length)];
}

function stickyAccentColor(sticky: Sticky): Color {
  const preset = sticky.colorTheme?.preset?._0;
  if (preset && PRESET_TO_RAYCAST[preset]) return PRESET_TO_RAYCAST[preset];
  return Color.Yellow;
}

function stickyEmoji(sticky: Sticky): string {
  const preset = sticky.colorTheme?.preset?._0;
  if (preset && PRESET_EMOJI[preset]) return PRESET_EMOJI[preset];
  return "⚪";
}

/// Builds a unicode progress bar like 🟡🟡🟡⚪⚪⚪⚪⚪ scaled to up to 8 dots.
function progressBar(done: number, total: number, emoji: string): string {
  if (total === 0) return "";
  const max = Math.min(total, 8);
  const filled = Math.min(Math.round((done / total) * max), max);
  return emoji.repeat(filled) + "⚪".repeat(max - filled);
}

function cleanTitle(title: string): string {
  // Trim leading single-line task previews accidentally appended to title
  return title.replace(/\s+/g, " ").trim();
}

function renderStickyDetail(sticky: Sticky): string {
  const open = sticky.tasks.filter((t) => !t.isCompleted);
  const done = sticky.tasks.filter((t) => t.isCompleted);

  const lines: string[] = [];
  lines.push(`# ${cleanTitle(sticky.title)}`);
  lines.push("");
  if (open.length > 0) {
    lines.push("### To do");
    open.forEach((t) => lines.push(`- [ ] ${t.title.replace(/\n/g, " ")}`));
    lines.push("");
  }
  if (done.length > 0) {
    lines.push("### Done");
    done.forEach((t) => lines.push(`- [x] ${t.title.replace(/\n/g, " ")}`));
  }
  if (sticky.tasks.length === 0) {
    lines.push("_No tasks yet. Add the first one._");
  }
  return lines.join("\n");
}

// MARK: - Main Command (sticky picker)

export default function Command() {
  const [stickies, setStickies] = useState<Sticky[]>([]);
  const [loaded, setLoaded] = useState(false);
  const [loadError, setLoadError] = useState(false);

  useEffect(() => {
    try {
      const raw = readFileSync(STICKY_PATH, "utf-8");
      const data: StickyFile = JSON.parse(raw);
      setStickies(data.stickies);
    } catch (e) {
      setLoadError(true);
      showToast({
        style: Toast.Style.Failure,
        title: "Couldn't read Sticky data",
        message: "Has Sticky been launched at least once?",
      });
    } finally {
      setLoaded(true);
    }
  }, []);

  if (loadError) {
    return (
      <List>
        <List.EmptyView
          icon={Icon.ExclamationMark}
          title="Couldn't load stickies"
          description="Make sure Sticky has run at least once, then try again."
        />
      </List>
    );
  }

  return (
    <List
      isLoading={!loaded}
      isShowingDetail
      searchBarPlaceholder="Find a sticky…"
      navigationTitle="Sticky"
    >
      {stickies.map((sticky) => {
        const accent = stickyAccentColor(sticky);
        const remaining = sticky.tasks.filter((t) => !t.isCompleted).length;
        const total = sticky.tasks.length;
        const allDone = total > 0 && remaining === 0;

        return (
          <List.Item
            key={sticky.id}
            title={cleanTitle(sticky.title)}
            icon={{ source: Icon.CircleFilled, tintColor: accent }}
            keywords={sticky.tasks.map((t) => t.title)}
            accessories={[
              {
                tag: {
                  value: `${remaining}`,
                  color: allDone ? Color.Green : remaining > 5 ? Color.Red : Color.SecondaryText,
                },
                tooltip: `${remaining} open / ${total} total`,
              },
            ]}
            detail={
              <List.Item.Detail
                markdown={renderStickyDetail(sticky)}
                metadata={
                  <List.Item.Detail.Metadata>
                    <List.Item.Detail.Metadata.TagList title="Colour">
                      <List.Item.Detail.Metadata.TagList.Item
                        text={sticky.colorTheme?.preset?._0 ?? "custom"}
                        color={accent}
                      />
                    </List.Item.Detail.Metadata.TagList>
                    <List.Item.Detail.Metadata.Separator />
                    <List.Item.Detail.Metadata.Label
                      title="Open"
                      text={`${remaining}`}
                      icon={{ source: Icon.Circle, tintColor: Color.SecondaryText }}
                    />
                    <List.Item.Detail.Metadata.Label
                      title="Done"
                      text={`${total - remaining}`}
                      icon={{ source: Icon.CheckCircle, tintColor: Color.Green }}
                    />
                    <List.Item.Detail.Metadata.Label title="Total" text={`${total}`} />
                  </List.Item.Detail.Metadata>
                }
              />
            }
            actions={
              <ActionPanel>
                <Action.Push
                  title="Add Task"
                  icon={Icon.Plus}
                  target={<TaskForm sticky={sticky} />}
                />
              </ActionPanel>
            }
          />
        );
      })}
      <List.EmptyView
        icon={Icon.MagnifyingGlass}
        title="No stickies match"
        description="Try a different search term."
      />
    </List>
  );
}

// MARK: - Task input form

function TaskForm({ sticky }: { sticky: Sticky }) {
  const [text, setText] = useState("");
  const [placeholder] = useState(randomPlaceholder);
  const { pop } = useNavigation();

  const emoji = stickyEmoji(sticky);
  const open_ = sticky.tasks.filter((t) => !t.isCompleted);
  const done_ = sticky.tasks.filter((t) => t.isCompleted);
  const total = sticky.tasks.length;
  const remaining = open_.length;
  const presetName = sticky.colorTheme?.preset?._0 ?? "custom";
  const recentOpen = open_.slice(-4).reverse();

  // Themed status: progress bar in the sticky's colour, then a friendly label.
  const statusText = (() => {
    if (total === 0) return "⚪⚪⚪⚪⚪  ·  Empty — be the first to add one";
    if (remaining === 0) return `${emoji.repeat(Math.min(total, 8))}  ·  ✨ All ${total} done`;
    const bar = progressBar(done_.length, total, emoji);
    return `${bar}  ·  ${done_.length} of ${total} done`;
  })();

  async function handleSubmit() {
    const trimmed = text.trim();
    if (!trimmed) {
      showToast({ style: Toast.Style.Failure, title: "Enter task text" });
      return;
    }
    const url = `sticky://add?stickyID=${sticky.id}&text=${encodeURIComponent(trimmed)}`;
    await open(url);
    await showToast({
      style: Toast.Style.Success,
      title: "Added",
      message: `to ${cleanTitle(sticky.title)}`,
    });
    await popToRoot();
  }

  return (
    <Form
      navigationTitle={`${emoji}  ${cleanTitle(sticky.title)}`}
      actions={
        <ActionPanel>
          <Action.SubmitForm title="Add Task" icon={Icon.Plus} onSubmit={handleSubmit} />
          <Action
            title="Pick Another Sticky"
            icon={Icon.ArrowLeftCircle}
            onAction={pop}
            shortcut={{ modifiers: ["cmd"], key: "[" }}
          />
        </ActionPanel>
      }
    >
      <Form.Description
        title="Sticky"
        text={`${emoji}  ${cleanTitle(sticky.title)}  ·  ${presetName}`}
      />
      <Form.Description title="Progress" text={statusText} />

      <Form.Separator />

      <Form.TextArea
        id="text"
        title="New task"
        value={text}
        onChange={setText}
        placeholder={placeholder}
        autoFocus
      />

      {recentOpen.length > 0 && (
        <>
          <Form.Separator />
          <Form.Description
            title="Open tasks"
            text={recentOpen
              .map((t) => `${emoji}  ${t.title.split("\n")[0].slice(0, 60)}`)
              .join("\n")}
          />
        </>
      )}

      {done_.length > 0 && (
        <Form.Description
          title="Recently done"
          text={done_
            .slice(-2)
            .reverse()
            .map((t) => `✅  ${t.title.split("\n")[0].slice(0, 60)}`)
            .join("\n")}
        />
      )}
    </Form>
  );
}
