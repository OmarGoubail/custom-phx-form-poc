defmodule FormxWeb.UserLive.FormComponent do
  use FormxWeb, :live_component

  alias Formx.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage user records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="user-form"
        phx-target={@myself}
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" phx-hook="InputValidation" />
        <.input field={@form[:nickname]} type="text" label="Nickname" phx-hook="InputValidation" />
        <:actions>
          <.button phx-disable-with="Saving...">Save User</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{user: user} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Accounts.change_user(user))
     end)}
  end

  @impl true
  def handle_event("validate_input", %{"name" => name, "value" => value} = params, socket) do
    IO.inspect(params, label: "\n[validate_input] Received Params")
    field_name_str =
      case Regex.run(~r/\[(\w+)\]/, name, capture: :all_but_first) do
        [field] -> field
        _ -> nil
      end

    IO.inspect(field_name_str, label: "[validate_input] Extracted Field Name String")

    if field_name_str do
      try do
        field_name_atom = String.to_existing_atom(field_name_str)
        IO.inspect(field_name_atom, label: "[validate_input] Field Name Atom")

        # Get the current *parameters* map from the form.
        current_params = Map.get(socket.assigns.form, :params, %{})
        IO.inspect(current_params, label: "[validate_input] Current Form Params")

        # Create the parameters map for the change function by merging the new value.
        # The params are nested under the form name ("user")
        params_for_change = Map.merge(current_params, %{field_name_str => value})
        IO.inspect(params_for_change, label: "[validate_input] Merged Params for Change")

        # Get the underlying user struct
        user_struct = socket.assigns.user

        # Create the changeset using the user struct and the *full merged* params
        changeset = Accounts.change_user(user_struct, params_for_change)
        IO.inspect(changeset, label: "[validate_input] Resulting Changeset")

        form = to_form(changeset, action: :validate)
        IO.inspect(form, label: "[validate_input] Final Form Struct")

        {:noreply, assign(socket, form: form)}
      rescue
        ArgumentError ->
          IO.inspect("ArgumentError converting field name atom", label: "[validate_input] Error")
          {:noreply, socket}
      end
    else
      IO.inspect("Could not parse field name from input name", label: "[validate_input] Error")
      {:noreply, socket}
    end
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    save_user(socket, socket.assigns.action, user_params)
  end

  defp save_user(socket, :edit, user_params) do
    case Accounts.update_user(socket.assigns.user, user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_user(socket, :new, user_params) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        notify_parent({:saved, user})

        {:noreply,
         socket
         |> put_flash(:info, "User created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
