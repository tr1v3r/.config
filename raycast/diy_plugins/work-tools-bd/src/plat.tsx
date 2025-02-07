const os = require("os");
const path = require("path");
const { loadYAML, searchObject } = require("./utils");
const { ActionPanel, Action, Icon, List } = require("@raycast/api");

const yamlFilepath = path.join(os.homedir(), ".config", "data.yaml");

function Command() {
  const data = loadYAML(yamlFilepath);
  if (!data || !data.webs) {
    return <List />;
  }
  // console.log(data.docs);

  return (
    <List>
      {Object.entries(data.webs.platform).map(([key, value]) => {
        return (
          <List.Item
            key={key}
            icon={data.webs.icon}
            title={key}
            subtitle={value}
            accessories={[{ icon: Icon.Cloud, text: "Platform" }]}
            actions={
              <ActionPanel>
                <Action.OpenInBrowser url={value} />
                <Action.CopyToClipboard content={value} />
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}

export default Command;
