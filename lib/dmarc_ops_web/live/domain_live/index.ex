defmodule DmarcOpsWeb.DomainLive.Index do
  use DmarcOpsWeb, :live_view

  alias DmarcOps.Inventory
  alias DmarcOps.Inventory.Domain

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="space-y-6">
        <!-- Header -->
        <div class="flex items-center justify-between">
          <div>
            <h1 class="text-2xl font-bold">Domains</h1>
            <p class="text-base-content/70">Manage your email domains and DNS records</p>
          </div>
          <.link patch={~p"/domains/new"} class="btn btn-primary">
            <.icon name="hero-plus" class="size-5" />
            Add Domain
          </.link>
        </div>

        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div class="stat bg-base-200 rounded-xl">
            <div class="stat-figure text-primary">
              <.icon name="hero-globe-alt" class="size-8" />
            </div>
            <div class="stat-title">Total Domains</div>
            <div class="stat-value text-primary"><%= length(@domains) %></div>
          </div>
          <div class="stat bg-base-200 rounded-xl">
            <div class="stat-figure text-success">
              <.icon name="hero-check-circle" class="size-8" />
            </div>
            <div class="stat-title">Verified</div>
            <div class="stat-value text-success"><%= count_by_status(@domains, :verified) %></div>
          </div>
          <div class="stat bg-base-200 rounded-xl">
            <div class="stat-figure text-warning">
              <.icon name="hero-clock" class="size-8" />
            </div>
            <div class="stat-title">Pending</div>
            <div class="stat-value text-warning"><%= count_by_status(@domains, :pending) %></div>
          </div>
          <div class="stat bg-base-200 rounded-xl">
            <div class="stat-figure text-accent">
              <.icon name="hero-shield-check" class="size-8" />
            </div>
            <div class="stat-title">Enforced</div>
            <div class="stat-value text-accent"><%= count_by_status(@domains, :enforced) %></div>
          </div>
        </div>

        <!-- Domains Table -->
        <div class="card bg-base-200">
          <div class="overflow-x-auto">
            <table class="table">
              <thead>
                <tr>
                  <th>Domain</th>
                  <th>Status</th>
                  <th>SPF</th>
                  <th>DKIM</th>
                  <th>DMARC</th>
                  <th>Policy</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                <tr :if={@domains == []}>
                  <td colspan="7" class="text-center py-12 text-base-content/50">
                    <.icon name="hero-globe-alt" class="size-12 mx-auto mb-4 opacity-50" />
                    <p class="font-medium">No domains yet</p>
                    <p class="text-sm">Add your first domain to get started</p>
                  </td>
                </tr>
                <tr :for={domain <- @domains} class="hover">
                  <td>
                    <.link navigate={~p"/domains/#{domain.id}"} class="font-medium hover:text-primary">
                      <%= domain.name %>
                    </.link>
                  </td>
                  <td><.status_badge status={domain.status} /></td>
                  <td><.auth_badge status={domain.spf_status} /></td>
                  <td><.auth_badge status={domain.dkim_status} /></td>
                  <td><.auth_badge status={domain.dmarc_status} /></td>
                  <td><.policy_badge policy={domain.current_policy} /></td>
                  <td>
                    <.link navigate={~p"/domains/#{domain.id}"} class="btn btn-ghost btn-sm">
                      <.icon name="hero-arrow-right" class="size-4" />
                    </.link>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Add Domain Modal -->
      <.modal :if={@live_action == :new} id="add-domain-modal" show on_cancel={JS.patch(~p"/domains")}>
        <:title>Add New Domain</:title>
        <.form for={@form} id="add-domain-form" phx-submit="save" class="space-y-4">
          <.input
            field={@form[:name]}
            type="text"
            label="Domain Name"
            placeholder="example.com"
            phx-mounted={JS.focus()}
            required
          />
          <p class="text-sm text-base-content/60">
            Enter your domain name without http:// or www
          </p>
          <div class="flex justify-end gap-3 pt-4">
            <.link patch={~p"/domains"} class="btn btn-ghost">Cancel</.link>
            <.button type="submit" class="btn btn-primary">
              <.icon name="hero-plus" class="size-5" />
              Add Domain
            </.button>
          </div>
        </.form>
      </.modal>
    </Layouts.app>
    """
  end

  # Status badge component
  defp status_badge(assigns) do
    color = case assigns.status do
      :pending -> "badge-warning"
      :verified -> "badge-success"
      :monitoring -> "badge-info"
      :enforced -> "badge-accent"
      _ -> "badge-ghost"
    end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"badge #{@color} badge-sm"}><%= @status %></span>
    """
  end

  # Auth status badge
  defp auth_badge(assigns) do
    ~H"""
    <%= if @status do %>
      <.icon name="hero-check-circle" class="size-5 text-success" />
    <% else %>
      <.icon name="hero-x-circle" class="size-5 text-error/50" />
    <% end %>
    """
  end

  # Policy badge
  defp policy_badge(assigns) do
    color = case assigns.policy do
      :none -> "badge-ghost"
      :quarantine -> "badge-warning"
      :reject -> "badge-success"
      _ -> "badge-ghost"
    end

    assigns = assign(assigns, :color, color)

    ~H"""
    <span class={"badge #{@color} badge-sm"}><%= @policy %></span>
    """
  end

  defp count_by_status(domains, status) do
    Enum.count(domains, &(&1.status == status))
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    domains = if user.agency_id, do: Inventory.list_domains(user.agency_id), else: []

    {:ok, assign(socket, domains: domains)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Domains")
    |> assign(:form, nil)
  end

  defp apply_action(socket, :new, _params) do
    changeset = Inventory.change_domain(%Domain{})

    socket
    |> assign(:page_title, "Add Domain")
    |> assign(:form, to_form(changeset))
  end

  @impl true
  def handle_event("save", %{"domain" => domain_params}, socket) do
    user = socket.assigns.current_scope.user

    case user.agency_id do
      nil ->
        {:noreply, put_flash(socket, :error, "You need to be part of an agency to add domains")}

      agency_id ->
        params = Map.put(domain_params, "agency_id", agency_id)

        case Inventory.create_domain(params) do
          {:ok, domain} ->
            {:noreply,
             socket
             |> put_flash(:info, "Domain #{domain.name} added successfully")
             |> push_patch(to: ~p"/domains")}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign(socket, :form, to_form(changeset))}
        end
    end
  end
end
