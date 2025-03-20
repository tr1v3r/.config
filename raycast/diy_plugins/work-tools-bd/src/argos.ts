import { open } from "@raycast/api";

export default async function main() {
  await open("https://cloud.bytedance.net/argos/overview/server_overview?from=now-1h&to=now");
}
