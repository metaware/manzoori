require 'spec_helper'
require 'pry'

describe Manzoori do

  before(:all) do

    ActiveRecord::Base.establish_connection({ 
      adapter: :sqlite3,
      database: ':memory:'
      })

    ActiveRecord::Schema.define do
      create_table :authors do |table|
        table.column :first_name, :string
        table.column :last_name, :string
        table.column :created_at, :datetime
        table.column :updated_at, :datetime        
      end

      create_table :posts do |table|
        table.column :title, :string
        table.column :body, :string
        table.column :state, :string
        table.column :object_diff, :text
        table.column :author_id, :text
        table.column :created_at, :datetime
        table.column :updated_at, :datetime
      end

      CreatePendingApprovals.new.change
    end

    class Author < ActiveRecord::Base
      has_many :posts
    end

    class Post < ActiveRecord::Base
      belongs_to :author

      attr_accessor :published

      requires_approval if: :approved?, 
        manzoori_history: :object_diff,
        skip_attributes: [:updated_at, :created_at],
        tracked_methods: [:author_name, :author_compact_name]

      def approved?
        self.state == 'approved'
      end

      def author_name
        "#{author.first_name} #{author.last_name}" if author.present?
      end

      def author_compact_name
        "#{author.first_name[0]}. #{author.last_name}" if author.present?
      end

    end

  end

  context 'when creating a new' do

    let(:post) { Post.create(title: 'metaware', state: 'approved') }

    it 'record gets created without the need for approval' do
      expect(post.title).to eq('metaware')
    end

    it 'record there are no pending approvals required' do
      expect(post.pending_approvals).to be_empty
    end

  end

  context "can handle method changes too" do

    let(:jasdeep)  { Author.create!(first_name: "Jasdeep", last_name: "Singh") }
    let(:manpreet) { Author.create!(first_name: "Manpreet", last_name: "Singh") }
    let(:post) { Post.create(title: 'metaware', state: 'approved', author: jasdeep) }

    context "simple" do
      before(:each) do
        post.author = manpreet
        post.save
      end

      it "should be able to track changes in method values too" do
        expect(post.manzoori_history).to eq({
          author_id:   ["1", "2"],
          author_name: ["Jasdeep Singh", "Manpreet Singh"],
          author_compact_name: ["J. Singh", "M. Singh"]
        }.with_indifferent_access)
      end
    end

    context "complex" do

      before(:each) do
        post.author = manpreet
        post.title = "Metaware Labs Inc"
        post.title = "Lets use some Elixir"
      end

      it "should be able to track method along with attributes" do
        post.save
        expect(post.manzoori_history).to eq({
          author_id: ["3", "4"],
          author_name: ["Jasdeep Singh", "Manpreet Singh"],
          author_compact_name: ["J. Singh", "M. Singh"],
          title: ["metaware", "Lets use some Elixir"]
        }.with_indifferent_access)
      end

      it "tracks only the first and the last change" do
        john = Author.create(first_name: "John", last_name: "Doe")
        jerry = Author.create(first_name: "Jerry", last_name: "Doe")
        terry = Author.create(first_name: "Terry", last_name: "Doe")
        post.author = john
        post.title = "John Doe was here"
        post.author = jerry
        post.title = "Jerry Doe was here"
        post.author = terry
        post.title = "Terry Doe was here"
        post.save
        expect(post.manzoori_history).to eq({
          author_id: ["5", "9"],
          author_name: ["Jasdeep Singh", "Terry Doe"],
          author_compact_name: ["J. Singh", "T. Doe"],
          title: ["metaware", "Terry Doe was here"]
        }.with_indifferent_access)
      end

    end

  end

  context 'existing record' do

    let(:post) { Post.create(title: 'metaware', state: 'approved') }

    before(:each) do
      post.title = 'new metaware'
    end

    context 'that requires approval' do

      before(:each) do
        post.save
        post.reload
      end

      it 'should not update or change after saving' do
        expect(post.title).to eq('metaware')
      end

      it 'should leave a key in manzoori_history when single attribute is changed' do
        expect(post.manzoori_history).to eq({ title: ["metaware", "new metaware"] }.with_indifferent_access)
      end

      it 'should leave multiple keys in manzoori_history when mutliple attributes are changed' do
        post.body = "Something new!"
        post.save
        expect(post.manzoori_history).to eq({ 
          title: ["metaware", "new metaware"],
          body: [nil, "Something new!"]
        }.with_indifferent_access)
      end

      it 'should prepare a trail of pending approvals' do
        expect(post.title).to eq('metaware')
        expect(post.pending_approvals).to be_present
      end

      it 'should allow to enquire if there are pending approvals' do
        expect(post.pending_approval?).to eq(true)
      end

      context 'tracks object_changes' do
        
        it 'should populate the object_changes column' do
          expect(post.pending_approvals.last.object_changes).to be_present
        end

        it 'should verify the object_changes are stored in a Hash' do
          expect(post.pending_approvals.last.object_changes).to be_a(Hash)
        end

        it 'should be possible to find out what attributes changed' do
          expect(post.pending_approvals.last.object_changes).to include('title')
        end

      end

      context 'raw_object' do
        
        it 'should populate raw_object column' do
          expect(post.pending_approvals.last.raw_object).to be_present
        end

        context 'serialized' do

          let(:serialized_object) { YAML.load(post.pending_approvals.last.raw_object) }

          it 'should be able to serialize raw_object back to object' do
            expect(serialized_object).to be_a(Post)
          end

          it 'should have the correct (new) attributes' do
            expect(serialized_object.title).to eq('new metaware')
          end

        end

      end
      
    end

    context 'multiple changes' do

      before(:each) do
        post.title = 'metaware 2'
        post.save
        post.title = 'metaware 3'
        post.save
        post.reload
      end

      it 'should recognize 2 pending approvals' do
        expect(post.pending_approvals.count).to eq(2)
      end

      it 'should recognize approvals in order' do
        pending_approvals = post.pending_approvals
        expect(pending_approvals.first.as_object.title).to eq('metaware 2')
        expect(pending_approvals.last.as_object.title).to eq('metaware 3')
      end

      it 'should be able to apply all changes to bring the object to desired state' do
        post.pending_approvals.each(&:approve_changes)
        post.reload
        expect(post.title).to eq('metaware 3')
      end

      it 'should know of only the latest change' do
        post.title = "metaware labs"
        post.save
        post.title = "Metaware Labs Inc"
        post.save
        expect(post.manzoori_history).to eq({
          title: ["metaware", "Metaware Labs Inc"]
        }.with_indifferent_access)
      end

    end

    context 'deserialized object' do

      before(:each) do
        post.title = 'metaware 2'
        post.save
        post.title = 'metaware 3'
        post.save
        post.reload
      end

      it 'should have the anticipated changes' do
        first = post.pending_approvals.first.as_object
        second = post.pending_approvals.last.as_object

        expect(first.title).to eq('metaware 2')
        expect(second.title).to eq('metaware 3')
      end

    end

    context '#approve_changes' do

      before(:each) do
        post.title = 'metaware 2'
        post.save
        post.reload
      end

      it 'should be able to revert the object back to the requested state' do
        post.pending_approvals.last.approve_changes
        post.reload
        expect(post.title).to eq('metaware 2')
      end

    end

    context '#reject_changes' do

      before(:each) do
        post.title = 'metaware 2'
        post.save
        post.reload
      end

      it 'should be able to revert the object back to the requested state' do
        post.pending_approvals.last.reject_changes
        post.reload
        expect(post.title).to eq('metaware')
      end

      it 'should clear any pending approvals in the queue' do
        post.pending_approvals.last.reject_changes
        post.reload
        expect(post.pending_approval?).to eq(false)
        expect(post.pending_approvals).to be_empty
      end

    end

    context 'does not requires approval' do

      before(:each) do
        expect(post).to receive(:approved?).and_return(false)
        post.save
        post.reload
      end

      it 'should just commit the changes' do
        expect(post.title).to eq('new metaware')
      end

      it 'should return false when approval is not required' do
        expect(post.pending_approval?).to eq(false)
      end

    end

  end

  context 'skip_attributes' do

    let(:post) { Post.create(title: 'metaware', state: 'approved') }

    it 'should allow the capability to skip certain attributes from the approval process' do
      original_updated_at = post.updated_at
      post.updated_at = post.updated_at + 1.hour
      post.save
      post.reload
      expect(post.updated_at).to eq(original_updated_at + 1.hour)
    end

    it 'should not track the skipped attributes' do
      post.title = 'metaware unapprovable'
      post.updated_at = post.updated_at + 10.minutes
      post.save
      post.reload
      expect(post.pending_approvals.last.object_changes).to include(:title)
      expect(post.pending_approvals.last.object_changes).to_not include(:updated_at)
    end

  end

  context 'approval queue is cleared after accepting changes' do

    let(:post) { Post.create(title: 'metaware', state: 'approved') }

    before(:each) do
      post.title = 'metaware 2'
      post.save
      post.title = 'metaware 3'
      post.save
      post.reload
    end

    it 'should clear approval queue after accepting changes' do
      expect(post.pending_approvals.count).to eq(2)
      post.approve_pending_changes
      expect(post.pending_approvals.count).to eq(0)
      expect(post.pending_approval?).to eq(false)
    end

  end

  context 'approval queue is cleared after rejecting changes' do

    let(:post) { Post.create(title: 'metaware', state: 'approved') }

    before(:each) do
      post.title = 'metaware 2'
      post.save
      post.title = 'metaware 3'
      post.save
      post.reload
    end

    it 'should clear approval queue after accepting changes' do
      expect(post.pending_approvals.count).to eq(2)
      post.reject_pending_changes
      expect(post.pending_approvals.count).to eq(0)
      expect(post.pending_approval?).to eq(false)
    end

  end

end