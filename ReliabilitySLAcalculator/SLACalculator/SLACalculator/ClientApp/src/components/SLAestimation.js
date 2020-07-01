import React, { Component } from 'react';
import './Styles.css';

export class SLAestimation extends Component {

    static renderSLAtable(slaEstimations, deleteEstimationEntry) {
        return (
            <div>
                <div className="estimation-toolbar">
                    <div className="estimation-expand-all"></div>
                    <div className="estimation-collapse-all"></div>
                    <div className="estimation-delete-all"></div>
                </div>
                {slaEstimations.map(sla =>
                    <div id={sla.id}>
                        <div className="estimation-head">
                            <div className="estimation-head-ec-arrow"><img src={"images/downarrow.png"} /></div>
                            <div className="estimation-head-title">{sla.key.categoryName}</div>
                            <div className="estimation-head-delete" onClick={ev => deleteEstimationEntry(ev)}><img src={"images/delete.png"} /></div>
                        </div>
                        <br />
                        <div className="estimation-layout">
                            <div className="estimation-service">
                                <div className="estimation-service-icon"><img src={"images/" + sla.key.imageFile}></img></div>
                                <div className="estimation-service-name"><p>{sla.key.name}</p></div>
                                <div className="estimation-sla"><p>SLA: {sla.key.sla} %</p></div>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        );
    }

    render() {
        if (this.props.dataSource.length > 0) {
            let contents = SLAestimation.renderSLAtable(this.props.dataSource, this.props.onDeleteEstimation);

            return (
                <div>
                    <br />
                    {contents}
                </div>
            );
        }

        return (<div></div>);
    }
}
