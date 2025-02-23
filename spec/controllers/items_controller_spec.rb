RSpec.describe ItemsController, type: :controller do
  let(:default_params) do
    { organization_id: @organization.to_param }
  end

  context "While signed in" do
    before do
      sign_in(@user)
    end

    describe "GET #index" do
      subject { get :index, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #new" do
      subject { get :new, params: default_params }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "GET #edit" do
      subject { get :edit, params: default_params.merge(id: create(:item, organization: @organization)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "PUT #update" do
      context "visible" do
        let(:item) { create(:item, visible_to_partners: false) }
        subject { put :update, params: default_params.merge(id: item.id, item: { value_in_cents: 100, visible_to_partners: true }) }
        it "should update visible_to_partners to true" do
          expect(subject).to redirect_to(items_path)
          expect(item.reload.visible_to_partners).to be true
        end
      end

      context "invisible" do
        let(:item) { create(:item, visible_to_partners: true) }
        subject { put :update, params: default_params.merge(id: item.id, item: { value_in_cents: 100, visible_to_partners: false }) }
        it "should update visible_to_partners to false" do
          expect(subject).to redirect_to(items_path)
          expect(item.reload.visible_to_partners).to be false
        end
      end

      context "kit name" do
        let(:kit) { create(:kit, name: "Test Kit") }
        let(:item) { create(:item, name: kit.name, kit_id: kit.id) }
        it "should update the kit name" do
          # ensure item name is same as kit name before update
          expect(item.present?).to be true
          expect(item.name).to eq kit.name
          # update the item name
          new_name = "Updated Kit"
          put :update, params: default_params.merge(id: item.id, item: { name: new_name })
          # ensure the name is updated in item & kit
          expect(item.reload.name).to eq new_name
          expect(kit.reload.name).to eq new_name
          expect(item.kit.name).to eq new_name
        end
      end
    end

    describe "GET #show" do
      subject { get :show, params: default_params.merge(id: create(:item, organization: @organization)) }
      it "returns http success" do
        expect(subject).to be_successful
      end
    end

    describe "DELETE #destroy" do
      subject { delete :destroy, params: default_params.merge(id: create(:item, organization: @organization)) }
      it "redirects to #index" do
        expect(subject).to redirect_to(items_path)
      end
    end

    describe "PATCH #restore" do
      context "with a soft-deleted item" do
        let!(:item) { create(:item, :inactive) }

        it "re-activates the item" do
          expect do
            patch :restore, params: default_params.merge(id: item.id)
          end.to change { Item.active.size }.by(1)
        end
      end

      context "with an active item" do
        let!(:item) { create(:item, :active) }
        it "does nothing" do
          expect do
            patch :restore, params: default_params.merge(id: item.id)
          end.to change { Item.active.size }.by(0)
        end
      end

      context "with another organizations item" do
        let!(:external_item) { create(:item, :inactive, organization: create(:organization)) }
        it "does nothing" do
          expect do
            patch :restore, params: default_params.merge(id: external_item.id)
          end.to change { Item.active.size }.by(0)
        end
      end
    end

    describe "POST #create" do
      let(:item_params) do
        {
          item: {
            name: "Really Good Item",
            partner_key: create(:base_item).partner_key,
            value_in_cents: 1001,
            package_size: 5,
            distribution_quantity: 30
          }
        }
      end

      context "with valid params" do
        it "should create an item" do
          expect do
            post :create, params: default_params.merge(item_params)
          end.to change { Item.count }.by(1)
        end

        it "should accept params with dollar signs, periods, and commas" do
          item_params["value_in_cents"] = "$5,432.10"
          post :create, params: default_params.merge(item_params)

          expect(response).not_to have_error
        end

        it "should redirect to the item page" do
          post :create, params: default_params.merge(item_params)

          expect(response).to redirect_to items_path
          expect(response).to have_notice
        end
      end

      context "with invalid params" do
        let(:bad_params) do
          { item: { bad: "params" } }
        end

        it "should show an error" do
          post :create, params: default_params.merge(bad_params)

          expect(response).to have_error
        end
      end
    end

    context "Looking at a different organization" do
      let(:object) { create(:item, organization: create(:organization)) }
      include_examples "requiring authorization"
    end

    describe "PATCH #remove_category" do
      let(:item_category) { create(:item_category) }
      let!(:item) { create(:item, item_category: item_category) }

      it "should remove an item's category" do
        patch :remove_category, params: default_params.merge(id: item.id)
        expect(item.reload.item_category).to be_nil
      end

      it "should redirect to the previous category page" do
        patch :remove_category, params: default_params.merge(id: item.id)

        expect(response).to redirect_to item_category_path(item_category)
        expect(response).to have_notice
      end
    end
  end

  context "While not signed in" do
    let(:object) { create(:item) }

    include_examples "requiring authorization"
  end
end
