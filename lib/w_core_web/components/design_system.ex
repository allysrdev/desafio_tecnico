defmodule WCoreWeb.DesignSystem do
  use Phoenix.Component

  attr :status, :atom, required: true,
    values: [:running, :idle, :error, :maintenance]

  def badge(assigns) do
    ~H"""
    <span class={["wc-badge", badge_class(@status)]}>
      <span class="wc-badge-dot"></span>
      <%= badge_label(@status) %>
    </span>
    """
  end

  defp badge_class(:running),     do: "wc-badge-running"
  defp badge_class(:idle),        do: "wc-badge-idle"
  defp badge_class(:error),       do: "wc-badge-error"
  defp badge_class(:maintenance), do: "wc-badge-maintenance"

  defp badge_label(:running),     do: "Operando"
  defp badge_label(:idle),        do: "Ocioso"
  defp badge_label(:error),       do: "Erro"
  defp badge_label(:maintenance), do: "Manutenção"

  attr :class, :string, default: ""
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div class={["wc-card", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true

  def stat(assigns) do
    ~H"""
    <div class="wc-stat-item">
      <span class="wc-stat-label"><%= @label %></span>
      <span class="wc-stat-value"><%= @value %></span>
    </div>
    """
  end

  attr :machine,     :map,     required: true
attr :highlighted, :boolean, default: false

def machine_card(assigns) do
  ~H"""
  <.card class={[
    "wc-machine-card",
    machine_card_class(@machine.status),
    @highlighted && "wc-machine-card-highlight"
  ]}>
    <div class="wc-machine-card-header">
      <div>
        <p class="wc-machine-card-id"><%= @machine.id %></p>
        <h3 class="wc-machine-card-name"><%= @machine.name %></h3>
      </div>
      <.badge status={@machine.status} />
    </div>
    <div class="wc-machine-card-stats">
      <.stat label="Temperatura" value={"#{@machine.temperature}°C"} />
      <.stat label="Uptime"      value={format_uptime(@machine.uptime)} />
      <.stat label="Atualizado"  value={format_time(@machine.last_updated)} />
    </div>
  </.card>
  """
end

  defp machine_card_class(:error), do: "wc-machine-card-error"
  defp machine_card_class(_),      do: ""

  attr :type,    :atom,   default: :info, values: [:info, :warning, :error, :success]
  attr :message, :string, required: true

  def alert(assigns) do
    ~H"""
    <div class={["wc-alert", alert_class(@type)]}>
      <span><%= alert_icon(@type) %></span>
      <span><%= @message %></span>
    </div>
    """
  end

  defp alert_class(:info),    do: "wc-alert-info"
  defp alert_class(:warning), do: "wc-alert-warning"
  defp alert_class(:error),   do: "wc-alert-error"
  defp alert_class(:success), do: "wc-alert-success"

  defp alert_icon(:info),    do: "ℹ"
  defp alert_icon(:warning), do: "⚠"
  defp alert_icon(:error),   do: "✕"
  defp alert_icon(:success), do: "✓"

  defp format_uptime(0),    do: "Offline"
  defp format_uptime(secs) do
    h = div(secs, 3600)
    m = div(rem(secs, 3600), 60)
    "#{h}h #{m}m"
  end

  defp format_time(dt) do
    dt
    |> DateTime.truncate(:second)
    |> Calendar.strftime("%H:%M:%S")
  end
end
