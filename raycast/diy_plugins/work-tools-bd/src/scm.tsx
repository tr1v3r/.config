const os = require("os");
const path = require("path");
const { loadYAML, searchObject } = require("./utils");
const { ActionPanel, Action, Icon, List } = require("@raycast/api");

const yamlFilepath = path.join(os.homedir(), ".config", "data.yaml");

function Command() {
  const data = loadYAML(yamlFilepath);
  if (!data || !data.jump) {
    return <List />;
  }

  const filteredResults = searchObject(data.jump, "scm");

  return (
    <List>
      {filteredResults.map((item) => (
        <List.Item
          key={item.text}
          icon={item.icon}
          title={item.text}
          subtitle={item.key}
          accessories={[{ text: "SCM" }]}
          actions={
            <ActionPanel>
              <Action.OpenInBrowser url={item.value} />
              <Action.CopyToClipboard content={item.value} />
            </ActionPanel>
          }
        />
      ))}
    </List>
  );
}

export default Command;
