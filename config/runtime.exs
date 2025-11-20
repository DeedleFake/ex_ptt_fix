import Config

config :ex_ptt_fix,
  key: System.get_env("PTT_FIX_KEY") || "key_comma",
  press: System.get_env("PTT_FIX_PRESS") || "comma"
