require "harassment/repositories/interaction_event_repository"

describe Harassment::Repositories::InteractionEventRepository do
  subject(:repository) { described_class.new }

  let(:event) do
    Harassment::InteractionEvent.build(
      message_id: 123,
      server_id: 456,
      channel_id: 789,
      author_id: 321,
      raw_content: "hello there",
    )
  end

  it "requires subclasses to implement #save" do
    expect { repository.save(event) }.to raise_error(NotImplementedError, /must implement #save/)
  end

  it "requires subclasses to implement #find" do
    expect { repository.find("123") }.to raise_error(NotImplementedError, /must implement #find/)
  end

  it "requires subclasses to implement #update_classification_status" do
    expect { repository.update_classification_status("123", Harassment::ClassificationStatus::CLASSIFIED) }.to raise_error(NotImplementedError, /must implement #update_classification_status/)
  end

  it "requires subclasses to implement #list_by_classification_status" do
    expect { repository.list_by_classification_status(Harassment::ClassificationStatus::PENDING) }.to raise_error(NotImplementedError, /must implement #list_by_classification_status/)
  end
end
