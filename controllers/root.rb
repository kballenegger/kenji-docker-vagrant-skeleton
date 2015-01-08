
class RootController < Kenji::Controller
  get '/index' do
    {hello: :world}
  end
end
