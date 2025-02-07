const os = require("os");
const path = require("path");
const { loadYAML, searchObject } = require("./utils");
const { ActionPanel, Action, Icon, List } = require("@raycast/api");

const yamlFilepath = path.join(os.homedir(), ".config", "data.yaml");

function Command() {
  const data = loadYAML(yamlFilepath);
  if (!data || !data.codebases || !data.codebases.repos) {
    return <List />;
  }

  const codes = data.codebases;
  const filteredResults = searchObject(codes.repos, "");

  return (
    <List>
      {Object.entries(filteredResults).map(([key, value]) => {
        return (
          <List.Item
            key={key}
            icon={codes.icon}
            title={key}
            subtitle={value}
            accessories={[{ icon: Icon.Code, text: "Repo" }]}
            actions={
              <ActionPanel>
                <Action.OpenInBrowser url={`${codes.host}${value}`} />
                <Action.CopyToClipboard content={`${codes.host}${value}`} />
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}

export default Command;
