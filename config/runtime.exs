import Config

config :ex_ptt_fix,
  key: System.get_env("PTT_FIX_KEY") || "comma"
