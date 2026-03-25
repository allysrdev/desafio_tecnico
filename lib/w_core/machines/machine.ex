defmodule WCore.Machines.Machine do
  @moduledoc """
  Struct que representa uma máquina no sistema.
  Equivalente a um TypeScript interface/type.
  """

  @type status :: :running | :idle | :error | :maintenance

  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    status: status(),
    temperature: float(),
    uptime: integer(),
    last_updated: DateTime.t()
  }

  defstruct [:id, :name, :status, :temperature, :uptime, :last_updated]

  @doc "Retorna lista inicial de máquinas mockadas"
  def initial_machines do
    [
      %__MODULE__{
        id: "m-001",
        name: "Torno CNC Alpha",
        status: :running,
        temperature: 72.4,
        uptime: 3600,
        last_updated: DateTime.utc_now()
      },
      %__MODULE__{
        id: "m-002",
        name: "Fresadora Beta",
        status: :idle,
        temperature: 45.0,
        uptime: 1800,
        last_updated: DateTime.utc_now()
      },
      %__MODULE__{
        id: "m-003",
        name: "Prensa Gamma",
        status: :error,
        temperature: 98.7,
        uptime: 0,
        last_updated: DateTime.utc_now()
      },
      %__MODULE__{
        id: "m-004",
        name: "Robô Delta",
        status: :running,
        temperature: 61.2,
        uptime: 7200,
        last_updated: DateTime.utc_now()
      },
      %__MODULE__{
        id: "m-005",
        name: "Extrusora Epsilon",
        status: :maintenance,
        temperature: 33.0,
        uptime: 0,
        last_updated: DateTime.utc_now()
      }
    ]
  end
end
