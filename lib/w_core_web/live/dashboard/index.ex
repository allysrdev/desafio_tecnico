defmodule WCoreWeb.DashboardLive do
  use WCoreWeb, :live_view

  alias WCore.Machines.Simulator

  def mount(_params, _session, socket) do
    # Se estiver conectado via WebSocket (não é pre-render)
    # se inscreve no PubSub — equivalente ao useEffect com subscribe
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WCore.PubSub, "machines:updates")
    end

    machines = Simulator.list_machines()

    {:ok, assign(socket, machines: machines, page_title: "W-Core Dashboard")}
  end

  # Recebe a mensagem do PubSub — equivalente ao ws.onmessage
  def handle_info({:machines_updated, machines}, socket) do
    {:noreply, assign(socket, machines: machines)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-8">
      <h1 class="text-2xl font-bold">W-Core — Motor de Estado</h1>

      <div class="mt-6 grid gap-4">
        <%= for machine <- @machines do %>
          <div class="border rounded p-4">
            <p class="font-semibold"><%= machine.name %></p>
            <p class="text-sm text-gray-500">Status: <%= machine.status %></p>
            <p class="text-sm text-gray-500">Temp: <%= machine.temperature %>°C</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
