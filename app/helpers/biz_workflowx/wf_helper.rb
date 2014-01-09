module BizWorkflowx
  module WfHelper
    include StateMachineLogx::StateMachineLogxHelper
    def event_action
      @title = t('Event Form') + '-' + t(params[:controller].camelize.demodulize.titleize.singularize)
      @workflow_model_object = params[:controller].camelize.singularize.constantize.find_by_id(params[:resource_id])  
      @workflow_result_url =   params[:wf_event].downcase + '_' + params[:controller].camelize.demodulize.tableize.singularize + '_path'
      @erb_code = find_config_const(params[:controller].sub('/', '_')+ '_' + params[:wf_event], params[:controller].camelize.deconstantize.titleize.singularize.downcase)
    end

    #wf_actions_def = find_config_const('wf_actions_def', params[:controller].camelize.deconstantize.titleize.singularize.downcase)   
    # eval(wf_actions_def) if wf_actions_def.present? 
=begin
    def submit
      wf_common_action('new', 'being_reviewed', 'submit')
    end
    
    def approve
      wf_common_action('being_reviewed', 'approved', 'approve')
    end
    
    def reject
      wf_common_action('being_reviewed', 'rejected', 'reject')
    end
=end
    #before_filter load the wf action def
    def self.included(base)
      base.before_filter :load_wf_action_def
    end
        
    protected
    
    def wf_common_action(from, to, event)
      model_sym = params[:controller].camelize.singularize.demodulize.downcase.to_sym
      model_id = params[model_sym][:id_noupdate].to_i
      @workflow_model_object = params[:controller].camelize.singularize.constantize.find_by_id(model_id) 
      @workflow_model_object.last_updated_by_id = session[:user_id]
      @workflow_model_object.transaction do
        if @workflow_model_object.update_attributes(params[model_sym], :as => :role_update)
          @workflow_model_object.send(event.strip + '!')
          StateMachineLogx::StateMachineLogxHelper.state_machine_logger(params[model_sym][:id_noupdate], params[:controller], session[:user_name], params[model_sym][:wf_comment], from, to, event, session[:user_id])
          redirect_to URI.escape(SUBURI + "/authentify/view_handler?index=0&msg=State Successfully Updated!")
        else
          @workflow_model_object = params[:controller].camelize.singularize.constantize.find_by_id(params[model_sym][:id_noupdate])
          flash.now[:error] = t('Data Error. State Not Saved!')
          render 'event_action'
        end
      end
    end
    
    def load_wf_action_def    
      engine_name = params[:controller][/.+\//].sub('/','')
      config_var_name = params[:controller][/\/.+/].sub('/','').singularize + 'wf_action_def' #quote_wf_action_def
      wf = Authentify::AuthentifyUtility.find_config_const(config_var_name, engine_name)
      wf = "def submit
      wf_common_action('new', 'being_reviewed', 'submit')
    end
    
    def approve
      wf_common_action('being_reviewed', 'approved', 'approve')
    end
    
    def reject
      wf_common_action('being_reviewed', 'rejected', 'reject')
    end"
      eval(wf) if wf.present?
    end
    
  end
end