export default async ({ $, client }) => {
  return {
    event: async ({ event }) => {
      if (event.type === "session.idle") {
        const session = await client.session.get({
          path: { id: event.properties.sessionID }
        });
        // Only notify if this is a primary session (no parent)
        if (!session.data.parentID) await $`notify-send "OpenCode finished" "Agent completed - check response"`;
      }
    }
  };
};
