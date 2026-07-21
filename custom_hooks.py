"""Custom LiteLLM hook: fixes Fabric's message formatting for strict-template models.

Fabric sends pattern+input as a single role=system message. Models with strict
Jinja chat templates (Qwen3 family: omnicoder-9b, ornith-9b) reject this because
they require a role=user message. This hook converts system→user at the proxy
level, so Fabric works without patching.
"""

from litellm import CustomLogger


STRICT_TEMPLATE_MODELS = {"omnicoder-9b", "ornith-9b"}


class MessageFixHook(CustomLogger):
    async def async_pre_call_hook(self, user_api_key_dict, cache, data, call_type):
        model = data.get("model", "")
        if model not in STRICT_TEMPLATE_MODELS:
            return data

        messages = data.get("messages", [])
        if len(messages) == 1 and messages[0].get("role") == "system":
            messages[0]["role"] = "user"
            data["messages"] = messages

        return data
