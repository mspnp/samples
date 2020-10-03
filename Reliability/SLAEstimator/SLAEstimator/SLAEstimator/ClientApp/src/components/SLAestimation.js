import React, { Component } from 'react';
import { SLAestimationTier } from './SLAestimationTier';
import './Styles.css';

export class SLAestimation extends Component {

    static renderSlaEstimationTier(tier, services, tiers, categories, deleteEstimationTier, expandCollapseEstimationTier,
        deleteEstimationCategory, deleteEstimationService, expandCollapseEstimationCategory, calculateTierSla, calculateDownTime, selectRegion) {
        return (
            <div key={tier}>
                <SLAestimationTier tierName={tier} tierServices={services}
                    tiers={tiers} categories={categories}
                    onDeleteEstimationCategory={deleteEstimationCategory}
                    onDeleteEstimationService={deleteEstimationService}
                    onExpandCollapseEstimationCategory={expandCollapseEstimationCategory}
                    onDeleteEstimationTier={deleteEstimationTier}
                    onExpandCollapseEstimationTier={expandCollapseEstimationTier}
                    onSelectRegion={selectRegion}
                    calculateTierTotal={calculateTierSla}
                    calculateDownTime={calculateDownTime}
                />
            </div>
        );
    }

    render() {
        if (this.props.slaEstimationData.length > 0) {
            const tiers = this.props.tiers.map(t => t.name);
            var tierContents = [];

            for (var i = 0; i < tiers.length; i++) {
                var tierServices = this.props.slaEstimationData
                    .filter(o => o.tier === tiers[i])
                    .map(svc => svc.key);

                if (tierServices.length > 0) {
                    var tierContent = SLAestimation.renderSlaEstimationTier(tiers[i], tierServices,
                        this.props.tiers,
                        this.props.categories,
                        this.props.onDeleteEstimationTier,
                        this.props.onExpandCollapseEstimationTier,
                        this.props.onDeleteEstimationCategory,
                        this.props.onDeleteEstimationService,
                        this.props.onExpandCollapseEstimationCategory,
                        this.props.calculateTierSla,
                        this.props.calculateDownTime,
                        this.props.onSelectTierRegion);

                    tierContents.push(tierContent);
                }
            }

            return (
                <div>
                    <div className="estimation-spacer">
                        <div className="estimation-expand-all" onClick={ev => this.props.onExpandAll(ev)}></div>
                        <div className="estimation-collapse-all" onClick={ev => this.props.onCollapseAll(ev)}></div>
                        <div className="estimation-delete-all" onClick={this.props.onDeleteAll}></div>
                    </div>
                    <br />
                    <div id="estimationPanel">
                        {tierContents}
                    </div>
                    <div>
                        <br />
                        <div className="estimation-totals-panel">
                            <br />
                            <div className="estimation-total-label-underline">Single Region Deployment</div>
                            <div className="estimation-total-label"><p>Composite SLA: {this.props.slaTotal} %</p></div>
                            <div className="estimation-total-label"><p>Maximum acceptable downtime in minutes /Month: {this.props.downTime} </p></div>
                            <br />
                            <div className="estimation-total-label-underline">Multi region Deployment</div>
                            <div className="estimation-total-label"><p>Composite SLA: {this.props.slaTotalMultiRegion} %</p></div>
                            <div className="estimation-total-label"><p>Maximum acceptable downtime in minutes /Month: {this.props.downTimeMultiRegion} </p></div>
                            <br />
                            <div className="estimation-notes">Some services have special considerations when designing applications for availability and service level guarantees.  Review the Microsoft Azure Service Level Agreements documentation for details.</div>
                        </div>
                    </div>
                </div>
            );
        }

        return (<div></div>);
    }
}
