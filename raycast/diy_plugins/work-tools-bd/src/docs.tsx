const os = require("os");
const path = require("path");
const { loadYAML, searchObject } = require("./utils");
const { ActionPanel, Action, Icon, List } = require("@raycast/api");

const yamlFilepath = path.join(os.homedir(), ".config", "data.yaml");

function Command() {
  const data = loadYAML(yamlFilepath);
  if (!data || !data.docs) {
    return <List />;
  }
  // console.log(data.docs);

  const filteredResults = {
    ...searchObject(data.docs.base, ""),
    ...searchObject(data.docs.folder, ""),
    ...searchObject(data.docs.doc, ""),
    ...searchObject(data.docs.sheets, ""),
  };
  // console.log(filteredResults);

  const docs = data.docs;
  return (
    <List>
      {Object.entries(filteredResults).map(([key, value]) => {
        return (
          <List.Item
            key={key}
            icon={
              value.startsWith("doc")
                ? docs.doc_icon
                : value.startsWith("sheets")
                  ? docs.sheet_icon
                  : value.startsWith("base")
                    ? docs.base_icon
                    : docs.folder_icon
            }
            title={key}
            // accessories={[{ icon: Icon.Text, text: "Docs" }]}
            actions={
              <ActionPanel>
                <Action.OpenInBrowser url={`${docs.host}${value}`} />
                <Action.CopyToClipboard content={`${docs.host}${value}`} />
              </ActionPanel>
            }
          />
        );
      })}
    </List>
  );
}

export default Command;
