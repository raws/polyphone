module Polyphone
  class Group
    attr_writer :client
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def client
      @client ||= Client.new
    end

    def write_graph(path)
      format = format_from_path(path)
      graph.output(format => path)
    end

    private

    def add_edges_between_user_nodes
      users_who_have_scrobbled.combination(2) do |first_user, second_user|
        compatibility = compatibility_between(first_user, second_user)

        if compatibility > 0.33
          options = {
            color: graph_edge_color(compatibility),
            dir: 'none',
            penwidth: (compatibility * 3).ceil
          }

          graph.add_edges(first_user.node, second_user.node, options)
        end
      end
    end

    def add_users_as_graph_nodes
      users_who_have_scrobbled.each do |user|
        user.node = graph.add_node(user.name, label: user.name)
      end
    end

    def compatibility_between(first_user, second_user)
      first_user.compatibility_with(second_user)
    end

    def configure_graph_style
      graph.node[:color] = 'black'
      graph.node[:shape] = 'ellipse'

      graph.edge[:color] = 'black'
      graph.edge[:label] = ''
      graph.edge[:style] = 'filled'
      graph.edge[:weight] = '1'

      graph[:ratio] = 'fill'
      graph[:size] = '10,10!'
    end

    def format_from_path(path)
      File.extname(path).sub(/\A\.*/, '')
    end

    def graph
      unless @graph
        @graph = GraphViz.new('polyphone')
        configure_graph_style
        add_users_as_graph_nodes
        add_edges_between_user_nodes
      end

      @graph
    end

    def graph_edge_color(compatibility)
      alpha = 255 * compatibility
      '#%02x%02x%02x%02x' % [255, 135, 67, alpha]
    end

    def users
      @users ||= client.group_members(name)
    end

    def users_who_have_scrobbled
      users.select do |user|
        user.play_count > 0
      end
    end
  end
end
