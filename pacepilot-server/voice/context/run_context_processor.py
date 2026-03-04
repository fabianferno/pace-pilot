# Placeholder processor — tool calls are handled via pipeline event handlers
class RunContextProcessor:
    def __init__(self, session_id: str):
        self.session_id = session_id
