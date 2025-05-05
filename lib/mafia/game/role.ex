defprotocol Mafia.Game.Role do
  def atom(role)
  def display_name(role)
  def target_list(role, state)
  def perform_action(role, state, target)
end
