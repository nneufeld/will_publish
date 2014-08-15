require 'spec_helper'

describe "WillPublish::Publishable" do

  describe "publish" do
    before(:each) do
      Author.create(name: 'DHH')
      Author.create(name: 'Matz')
      @draft = Guide.create(name: 'Test Guide', description: 'Guide description', created_at: 5.hours.ago, updated_at: 2.hours.ago)
      @draft.steps << Step.create(name: 'Installation', description: 'Do this...')
      @draft.steps << Step.create(name: 'Configuration', description: 'Do this...')
      @draft.authors = Author.all
      @draft.publish
      @published = Guide.last
    end

    it "should create a new object with the same attributes" do
      expect(Guide.count).to eq(2)
      expect(@published.name).to eq(@draft.name)
      expect(@published.description).to eq(@draft.description)
    end

    it "should create a copy of object's associations" do
      expect(@published.authors).to eq(Author.all)
      expect(@published.steps[0].name).to eq('Installation')
      expect(@published.steps[1].name).to eq('Configuration')
    end

    it "should not touch associations on the published version that are filtered out by only/except" do
      comment = @published.comments.create(title: 'Great Guide!', body: 'Very Helpful!')
      step_comment = @published.steps[1].comments.create(title: 'Did Not Work', body: 'Need Help')
      @draft.publish
      @published.reload
      expect(@published.steps[1].comments.first).to eq(step_comment)
    end

    it "should not touch attributes on the published version that are filtered out by only/except" do
      @published.update_attributes(like_count: 5)
      @published.steps[0].update_attributes(like_count: 2)
      @draft.publish
      @published.reload
      expect(@published.like_count).to eq(5)
      expect(@published.steps[0].like_count).to eq(2)
    end

    it "should not copy the active record timestamps" do
      expect(@published.created_at).not_to eq(@draft.created_at)
      expect(@published.updated_at).not_to eq(@draft.updated_at)
    end

    it "should set the is_published_version flag of the published copy to true" do
      expect(@draft.is_published_version).to eq(false)
      expect(@published.is_published_version).to eq(true)
    end

    context "when the object has already been published" do
      before(:each) do
        @draft.update_attributes(name: 'Updated Name')
        @draft.publish
      end

      it "should not create a second published copy" do
        expect(Guide.count).to eq(2)
      end

      it "should update the attributes of the published copy" do
        @published.reload
        expect(@published.name).to eq('Updated Name')
      end
    end

    it "should execute the callbacks in the correct order" do
      expect(@draft.callback_order).to eq(['before', 'around before', 'around after', 'after'])
    end

    context "when a before_filter returns false" do
      it "should halt publishing and return false" do
        @draft.callback_order = []
        @draft.return_false_before_publish = true
        @draft.update_attributes(name: 'Updated Name')
        expect(@draft.publish).to eq(false)
        @published.reload
        expect(@published.name).to eq('Test Guide') # published object remained unchanged
        expect(@draft.callback_order).to eq(['before'])
      end
    end

    context "when an after_filter returns false" do
      it "should return true and successfully complete the publishing" do
        @draft.return_false_after_publish = true
        @draft.update_attributes(name: 'Updated Name')
        expect(@draft.publish).to eq(true)
        @published.reload
        expect(@published.name).to eq('Updated Name') # published object remained unchanged
      end
    end

    context "when an after_filter raises an exception" do
      it "should raise an exception and rollback the publish transaction" do
        @draft.raise_exception_after_publish = true
        @draft.update_attributes(name: 'Updated Name')
        expect { @draft.publish }.to raise_error("After pubish error!")
        @published.reload
        expect(@published.name).to eq('Test Guide') # published object remained unchanged
      end
    end
  end

  describe "published" do
    before(:each) do
      @draft = Guide.create(name: 'Test Guide', description: 'Guide description')
    end

    context "when called on a draft that has been published" do
      it "should return the published copy of the publication" do
        @draft.publish

        published = @draft.published
        expect(published.is_published_version).to eq(true)
        expect(published).to eq(Guide.last)
      end
    end

    context "when called on a draft that has not been published" do
      it "should return nil" do
        expect(@draft.published).to be_nil
      end
    end

    context "when called on a published version" do
      it "should return nil" do
        @draft.publish

        published = @draft.published
        expect(published.published).to be_nil
      end
    end
  end

  describe "draft" do
    before(:each) do
      @draft = Guide.create(name: 'Test Guide', description: 'Guide description')
      @draft.publish
      @published = @draft.published
    end

    context "when called on a published version" do
      it "should return the draft version of the publication" do
        expect(@published.draft).to eq(@draft)
      end
    end

    context "when called on a draft" do
      it "should return nil" do
        expect(@draft.draft).to be_nil
      end
    end
  end

end