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
      requires_approval if: :approved?

      def approved?
        true
      end
    end

  end

  context 'new record' do

    let(:post) { Post.create(title: 'metaware') }

    it 'should create a new record without any approval' do
      expect(post.title).to eq('metaware')
    end

    it 'should not have any pending approvals' do
      expect(post.pending_approvals).to be_empty
    end

  end

  context 'existing record' do

    let(:post) { Post.create(title: 'metaware') }

    before(:each) do
      post.title = 'new metaware'
    end

    context 'requires approval' do

      before(:each) do
        post.save
        post.reload
      end

      it 'doesnt update or change the record that requires approval' do
        expect(post.title).to eq('metaware')
      end

      it 'saves a single record that contains pending changes' do
        expect(post.title).to eq('metaware')
        expect(post.pending_approvals).to be_present
      end

      it 'should return true when approval is required' do
        expect(post.pending_approval?).to eq(true)
      end

      context 'object_changes' do
        
        it 'should populate object_changes column' do
          expect(post.pending_approvals.last.object_changes).to be_present
        end

        it 'should be of type hash' do
          expect(post.pending_approvals.last.object_changes).to be_a(Hash)
        end

        it 'should contain the attributes that changed' do
          expect(post.pending_approvals.last.object_changes).to include('title', 'updated_at')
        end

      end

      context 'raw_object' do
        
        it 'should populate serialized_object column' do
          expect(post.pending_approvals.last.raw_object).to be_present
        end


        context 'serialized raw object' do

          let(:serialized_object) { YAML.load(post.pending_approvals.last.raw_object) }

          it 'should be able to serialize raw_object back to object' do
            expect(serialized_object).to be_a(Post)
          end

          it 'should have the correct (new) attributes' do
            expect(serialized_object.title).to eq('metaware')
          end

        end

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