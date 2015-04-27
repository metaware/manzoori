require 'spec_helper'

describe Pravangi do

  before(:all) do

    ActiveRecord::Base.establish_connection({ 
      adapter: :sqlite3,
      database: ':memory:'
      })

    ActiveRecord::Schema.define do
      create_table :posts do |table|
        table.column :title, :string
        table.column :body, :string
        table.column :created_at, :datetime
        table.column :updated_at, :datetime
      end

      CreatePendingApprovals.new.change
    end

    class Post < ActiveRecord::Base
      requires_approval if: :approved?, enabled: true

      def approved?
        true
      end
    end

  end

  context 'when creating a new' do

    let(:post) { Post.create(title: 'metaware') }

    it 'record gets created without the need for approval' do
      expect(post.title).to eq('metaware')
    end

    it 'record there are no pending approvals required' do
      expect(post.pending_approvals).to be_empty
    end

  end

  context 'existing record' do

    let(:post) { Post.create(title: 'metaware') }

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
          expect(post.pending_approvals.last.object_changes).to include('title', 'updated_at')
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
        skip
        # expect(post.pending_approvals.first).to eq(2)
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

    context '#commit' do

      before(:each) do
        post.title = 'metaware 2'
        post.save
        post.reload
      end

      it 'should be able to revert the object back to the requested state' do
        post.pending_approvals.last.commit
        post.reload
        expect(post.title).to eq('metaware 2')
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

end